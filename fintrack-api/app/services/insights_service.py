import json
import logging
import os
from datetime import datetime, timedelta
from typing import Optional

import httpx

from ..schemas.category import CategoryOut
from ..schemas.insights import InsightOut, InsightsResponse
from ..schemas.transaction import TransactionOut

logger = logging.getLogger(__name__)

GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_URL_TEMPLATE = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
)

_ALLOWED_ICONS = {
    "warning", "savings", "trending_up", "trending_down", "steady",
    "pie_chart", "priority_high", "calendar", "weekend",
    "check_circle", "query_stats", "auto_awesome",
}
_ALLOWED_SENTIMENTS = {"positive", "warning", "neutral"}


def _parse_date(value: str) -> datetime:
    # Transaction dates are ISO-8601 strings (date.toIso8601String() on the
    # Dart side); handle a trailing 'Z' that fromisoformat rejects pre-3.11.
    return datetime.fromisoformat(value.replace("Z", "+00:00")).replace(tzinfo=None)


def _month_start(d: datetime) -> datetime:
    return datetime(d.year, d.month, 1)


def _prev_month_start(d: datetime) -> datetime:
    if d.month == 1:
        return datetime(d.year - 1, 12, 1)
    return datetime(d.year, d.month - 1, 1)


def _sum_amount(transactions: list[TransactionOut], type_: str) -> float:
    return sum(t.amount for t in transactions if t.type == type_)


def _pct(fraction: float) -> str:
    return f"{round(abs(fraction) * 100)}%"


def _money(amount: float) -> str:
    return f"RM {amount:,.2f}"


def _compute_health_score(transactions: list[TransactionOut], now: datetime) -> dict:
    this_month_start = _month_start(now)
    last_month_start = _prev_month_start(now)

    total_income = _sum_amount(transactions, "income")
    total_expense = _sum_amount(transactions, "expense")
    this_month_expense = _sum_amount(
        [t for t in transactions if _parse_date(t.date) >= this_month_start], "expense"
    )
    last_month_expense = _sum_amount(
        [
            t for t in transactions
            if last_month_start <= _parse_date(t.date) < this_month_start
        ],
        "expense",
    )

    savings_rate = (total_income - total_expense) / total_income if total_income > 0 else 0.0
    savings_score = round((max(-0.5, min(0.5, savings_rate)) + 0.5) * 100)

    if last_month_expense > 0:
        delta = (this_month_expense - last_month_expense) / last_month_expense
        trend_score = round((max(-0.5, min(0.5, -delta)) + 0.5) * 100)
        score = round(savings_score * 0.6 + trend_score * 0.4)
    else:
        score = savings_score
    score = max(0, min(100, score))

    if score >= 80:
        label, sentiment = "Excellent", "positive"
    elif score >= 60:
        label, sentiment = "Good", "positive"
    elif score >= 40:
        label, sentiment = "Fair", "neutral"
    else:
        label, sentiment = "Needs attention", "warning"

    return {
        "score": score,
        "label": label,
        "sentiment": sentiment,
        "total_income": total_income,
        "total_expense": total_expense,
        "this_month_expense": this_month_expense,
        "last_month_expense": last_month_expense,
    }


def _daily_expense_series(transactions: list[TransactionOut], now: datetime, days: int = 14) -> list[float]:
    today = datetime(now.year, now.month, now.day)
    totals = [0.0] * days
    for t in transactions:
        if t.type != "expense":
            continue
        d = _parse_date(t.date)
        d = datetime(d.year, d.month, d.day)
        diff = (today - d).days
        if 0 <= diff < days:
            totals[days - 1 - diff] += t.amount
    return totals


def _find_category(categories: list[CategoryOut], category_id: str) -> Optional[CategoryOut]:
    for c in categories:
        if c.id == category_id:
            return c
    return None


def _gather_facts(
    transactions: list[TransactionOut],
    categories: list[CategoryOut],
    now: datetime,
    health: dict,
) -> dict:
    """Deterministic aggregates - the same facts the rule-based fallback uses,
    and what gets handed to Gemini so it never has to invent numbers."""
    this_month_start = _month_start(now)
    last_month_start = _prev_month_start(now)
    expenses = [t for t in transactions if t.type == "expense"]

    facts: dict = {
        "transaction_count": len(transactions),
        "total_income": health["total_income"],
        "total_expense": health["total_expense"],
        "this_month_expense": health["this_month_expense"],
        "last_month_expense": health["last_month_expense"],
        "savings_rate": (
            (health["total_income"] - health["total_expense"]) / health["total_income"]
            if health["total_income"] > 0 else None
        ),
        "month_over_month_delta": None,
        "projected_month_end": None,
        "projected_vs_last_month_delta": None,
        "top_category": None,
        "biggest_expense": None,
        "top_weekday": None,
        "weekend_vs_weekday": None,
        "no_spend_days_last_7": None,
    }

    last_month_expense = health["last_month_expense"]
    this_month_expense = health["this_month_expense"]
    if last_month_expense > 0:
        facts["month_over_month_delta"] = (this_month_expense - last_month_expense) / last_month_expense

        day_of_month = now.day
        days_in_month = (
            datetime(now.year + (1 if now.month == 12 else 0), now.month % 12 + 1, 1) - timedelta(days=1)
        ).day
        if day_of_month >= 3 and this_month_expense > 0:
            projected = this_month_expense / day_of_month * days_in_month
            facts["projected_month_end"] = projected
            facts["projected_vs_last_month_delta"] = (projected - last_month_expense) / last_month_expense

    total_expense = health["total_expense"]
    if expenses and total_expense > 0:
        totals_by_cat: dict[str, float] = {}
        for t in expenses:
            totals_by_cat[t.category_id] = totals_by_cat.get(t.category_id, 0) + t.amount
        top_cat_id, top_amount = max(totals_by_cat.items(), key=lambda kv: kv[1])
        cat = _find_category(categories, top_cat_id)
        facts["top_category"] = {
            "name": cat.name if cat else "Uncategorised",
            "amount": top_amount,
            "share": top_amount / total_expense,
        }

    if expenses:
        biggest = max(expenses, key=lambda t: t.amount)
        cat = _find_category(categories, biggest.category_id)
        facts["biggest_expense"] = {
            "title": biggest.title,
            "amount": biggest.amount,
            "category": cat.name if cat else None,
            "date": biggest.date,
        }

    if len(expenses) >= 5:
        totals_by_weekday: dict[int, float] = {}
        for t in expenses:
            wd = _parse_date(t.date).weekday()  # Monday=0..Sunday=6
            totals_by_weekday[wd] = totals_by_weekday.get(wd, 0) + t.amount
        top_wd, top_wd_amount = max(totals_by_weekday.items(), key=lambda kv: kv[1])
        names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        facts["top_weekday"] = {"name": names[top_wd], "amount": top_wd_amount}

    if len(expenses) >= 6:
        weekend_total = weekday_total = 0.0
        weekend_days: set[str] = set()
        weekday_days: set[str] = set()
        for t in expenses:
            d = _parse_date(t.date)
            key = f"{d.year}-{d.month}-{d.day}"
            if d.weekday() >= 5:  # Saturday=5, Sunday=6
                weekend_total += t.amount
                weekend_days.add(key)
            else:
                weekday_total += t.amount
                weekday_days.add(key)
        if weekend_days and weekday_days:
            weekend_avg = weekend_total / len(weekend_days)
            weekday_avg = weekday_total / len(weekday_days)
            if weekday_avg > 0:
                facts["weekend_vs_weekday"] = {
                    "weekend_avg": weekend_avg,
                    "weekday_avg": weekday_avg,
                    "delta": (weekend_avg - weekday_avg) / weekday_avg,
                }

    today = datetime(now.year, now.month, now.day)
    spent_days: set[str] = set()
    for t in expenses:
        d = _parse_date(t.date)
        d0 = datetime(d.year, d.month, d.day)
        diff = (today - d0).days
        if 0 <= diff < 7:
            spent_days.add(f"{d0.year}-{d0.month}-{d0.day}")
    facts["no_spend_days_last_7"] = 7 - len(spent_days)

    return facts


def _rule_based_insights(facts: dict) -> list[InsightOut]:
    """Deterministic port of insights_service.dart's rule engine - used as the
    fallback when the Gemini call is unavailable or fails."""
    if facts["transaction_count"] < 3:
        return [
            InsightOut(
                icon="auto_awesome",
                title="Not enough data yet",
                message=(
                    "Add a few more transactions and check back — insights get "
                    "more useful the more history you have."
                ),
                sentiment="neutral",
            )
        ]

    insights: list[InsightOut] = []

    rate = facts["savings_rate"]
    if rate is not None:
        if rate < 0:
            insights.append(InsightOut(
                icon="warning", title="Spending more than you earn",
                message=f"Overall, your expenses are {_pct(rate)} higher than your income. "
                        "It may be worth reviewing your biggest spending categories below.",
                sentiment="warning",
            ))
        elif rate < 0.1:
            insights.append(InsightOut(
                icon="savings", title="Thin savings margin",
                message=f"You are keeping {_pct(rate)} of what you earn. A small cut to your "
                        "top spending category could give you more of a buffer.",
                sentiment="warning",
            ))
        else:
            insights.append(InsightOut(
                icon="trending_up", title="Healthy savings rate",
                message=f"You are saving {_pct(rate)} of your income overall. Keep it up.",
                sentiment="positive",
            ))

    delta = facts["month_over_month_delta"]
    if delta is not None:
        this_m, last_m = facts["this_month_expense"], facts["last_month_expense"]
        if abs(delta) < 0.05:
            insights.append(InsightOut(
                icon="steady", title="Spending is steady",
                message=f"This month's spending ({_money(this_m)}) is about the same as last month.",
                sentiment="neutral",
            ))
        elif delta > 0:
            insights.append(InsightOut(
                icon="trending_up", title="Spending is up this month",
                message=f"You have spent {_pct(delta)} more than last month so far "
                        f"({_money(this_m)} vs {_money(last_m)}).",
                sentiment="warning",
            ))
        else:
            insights.append(InsightOut(
                icon="trending_down", title="Spending is down this month",
                message=f"You have spent {_pct(delta)} less than last month so far "
                        f"({_money(this_m)} vs {_money(last_m)}).",
                sentiment="positive",
            ))

    proj_delta = facts["projected_vs_last_month_delta"]
    if proj_delta is not None and abs(proj_delta) >= 0.08:
        insights.append(InsightOut(
            icon="query_stats",
            title="On track to overspend" if proj_delta > 0 else "On track to spend less",
            message=f"At your current pace, this month could end around "
                    f"{_money(facts['projected_month_end'])}, {_pct(proj_delta)} "
                    f"{'more' if proj_delta > 0 else 'less'} than last month's "
                    f"{_money(facts['last_month_expense'])}.",
            sentiment="warning" if proj_delta > 0 else "positive",
        ))

    top_cat = facts["top_category"]
    if top_cat is not None:
        insights.append(InsightOut(
            icon="pie_chart", title="Biggest spending category",
            message=f"{top_cat['name']} makes up {_pct(top_cat['share'])} of your total "
                    f"spending ({_money(top_cat['amount'])}).",
            sentiment="warning" if top_cat["share"] > 0.4 else "neutral",
        ))

    biggest = facts["biggest_expense"]
    if biggest is not None:
        date_str = _parse_date(biggest["date"]).strftime("%d %b").lstrip("0")
        cat_suffix = f" ({biggest['category']})" if biggest["category"] else ""
        insights.append(InsightOut(
            icon="priority_high", title="Largest single expense",
            message=f"{_money(biggest['amount'])} on \"{biggest['title']}\"{cat_suffix} — {date_str}.",
            sentiment="neutral",
        ))

    top_weekday = facts["top_weekday"]
    if top_weekday is not None:
        insights.append(InsightOut(
            icon="calendar", title="Spending pattern",
            message=f"You tend to spend the most on {top_weekday['name']}s "
                    f"({_money(top_weekday['amount'])} total).",
            sentiment="neutral",
        ))

    wvw = facts["weekend_vs_weekday"]
    if wvw is not None and abs(wvw["delta"]) >= 0.15:
        more_on_weekend = wvw["delta"] > 0
        insights.append(InsightOut(
            icon="weekend",
            title="Weekends cost more" if more_on_weekend else "Weekdays cost more",
            message=f"You spend {_money(wvw['weekend_avg'] if more_on_weekend else wvw['weekday_avg'])} "
                    f"a day on average {'on weekends' if more_on_weekend else 'on weekdays'}, "
                    f"{_pct(wvw['delta'])} more than {'weekdays' if more_on_weekend else 'weekends'} "
                    f"({_money(wvw['weekday_avg'] if more_on_weekend else wvw['weekend_avg'])}).",
            sentiment="neutral",
        ))

    no_spend = facts["no_spend_days_last_7"]
    if no_spend is not None and no_spend > 0:
        insights.append(InsightOut(
            icon="check_circle",
            title="No spending in the past week" if no_spend == 7 else "No-spend days this week",
            message=(
                "You have not logged a single expense in the last 7 days."
                if no_spend == 7 else
                f"You had {no_spend} no-spend day{'' if no_spend == 1 else 's'} out of the last 7."
            ),
            sentiment="positive" if no_spend >= 4 else "neutral",
        ))

    return insights


_INSIGHT_RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "ai_summary": {
            "type": "STRING",
            "description": "A short (1-3 sentence), friendly, specific overview of the user's "
                            "financial situation this period, referencing the actual numbers given.",
        },
        "insights": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "icon": {"type": "STRING", "enum": sorted(_ALLOWED_ICONS)},
                    "title": {"type": "STRING"},
                    "message": {"type": "STRING"},
                    "sentiment": {"type": "STRING", "enum": sorted(_ALLOWED_SENTIMENTS)},
                },
                "required": ["icon", "title", "message", "sentiment"],
            },
        },
    },
    "required": ["ai_summary", "insights"],
}


def _build_prompt(facts: dict) -> str:
    return (
        "You are a friendly, concise personal-finance coach inside a budgeting app. "
        "Below are pre-computed, already-correct facts about one user's transaction history "
        "(currency MYR). Do not invent or recompute numbers - only use the ones given. "
        "Write 3 to 6 short insight cards (title + one or two sentence message) that a real "
        "person would find useful and specific, prioritising the most actionable or notable "
        "facts. Pick the icon that best matches each insight's theme, and a sentiment "
        "('positive' for good news, 'warning' for something to watch, 'neutral' otherwise). "
        "Also write a short overall summary. Keep tone warm but not preachy, and avoid "
        "generic advice unrelated to the given numbers.\n\n"
        f"Facts (JSON): {json.dumps(facts, default=str)}"
    )


def _call_gemini(facts: dict) -> Optional[dict]:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return None

    url = GEMINI_URL_TEMPLATE.format(model=GEMINI_MODEL)
    body = {
        "contents": [{"parts": [{"text": _build_prompt(facts)}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": _INSIGHT_RESPONSE_SCHEMA,
        },
    }
    try:
        res = httpx.post(
            url,
            json=body,
            headers={"x-goog-api-key": api_key},
            timeout=20.0,
        )
        res.raise_for_status()
        data = res.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        parsed = json.loads(text)

        insights = []
        for item in parsed.get("insights", []):
            icon = item.get("icon") if item.get("icon") in _ALLOWED_ICONS else "auto_awesome"
            sentiment = item.get("sentiment") if item.get("sentiment") in _ALLOWED_SENTIMENTS else "neutral"
            insights.append(InsightOut(
                icon=icon, title=item["title"], message=item["message"], sentiment=sentiment,
            ))
        if not insights:
            return None
        return {"insights": insights, "ai_summary": parsed.get("ai_summary")}
    except Exception:
        logger.exception("Gemini insight generation failed; falling back to rule-based insights")
        return None


def build_insights(transactions: list[TransactionOut], categories: list[CategoryOut]) -> InsightsResponse:
    now = datetime.now()
    health = _compute_health_score(transactions, now)
    daily_series = _daily_expense_series(transactions, now)

    ai_generated = False
    ai_summary = None
    insights: list[InsightOut]

    if len(transactions) < 3:
        insights = _rule_based_insights({"transaction_count": len(transactions)})
    else:
        facts = _gather_facts(transactions, categories, now, health)
        gemini_result = _call_gemini(facts)
        if gemini_result is not None:
            insights = gemini_result["insights"]
            ai_summary = gemini_result["ai_summary"]
            ai_generated = True
        else:
            insights = _rule_based_insights(facts)

    return InsightsResponse(
        health_score={
            "score": health["score"],
            "label": health["label"],
            "sentiment": health["sentiment"],
        },
        total_income=health["total_income"],
        total_expense=health["total_expense"],
        daily_expense_series=daily_series,
        insights=insights,
        ai_summary=ai_summary,
        ai_generated=ai_generated,
    )
