from typing import Literal

from pydantic import BaseModel

Sentiment = Literal["positive", "warning", "neutral"]

# Matches the icon switch in fintrack-mobile/lib/screens/ai_insights_screen.dart
IconKey = Literal[
    "warning",
    "savings",
    "trending_up",
    "trending_down",
    "steady",
    "pie_chart",
    "priority_high",
    "calendar",
    "weekend",
    "check_circle",
    "query_stats",
    "auto_awesome",
]


class HealthScoreOut(BaseModel):
    score: int
    label: str
    sentiment: Sentiment


class InsightOut(BaseModel):
    icon: IconKey
    title: str
    message: str
    sentiment: Sentiment


class InsightsResponse(BaseModel):
    health_score: HealthScoreOut
    total_income: float
    total_expense: float
    daily_expense_series: list[float]
    insights: list[InsightOut]
    ai_summary: str | None = None
    # False when the Gemini call failed/was unavailable and the rule-based
    # fallback was used instead - lets the UI be honest about the source.
    ai_generated: bool
