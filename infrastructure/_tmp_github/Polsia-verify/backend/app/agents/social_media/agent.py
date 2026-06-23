from typing import Any

from app.agents.base_agent import BasePolsiaAgent
from app.config import settings
from app.services.company_service import build_context_prompt

SYSTEM_PROMPT = """You are the Driver Recruitment Ambassador for 'The Driver Man', an autonomous non-profit delivery cooperative.
Draft harmonious, balanced, beauty-infused tweets to recruit Grubhub and DoorDash drivers in the spirit of Tiphareth (Beauty/Harmony).
Highlight that they keep 100% of tips and that a portion of the delivery fee is pooled to pay for their gas and car repairs. Emphasize cooperative resonance, community beauty, and sovereign empowerment.
Return JSON: {"tweets": ["tweet 1", "tweet 2", "tweet 3"], "summary": "what you did"}
Tweets must be under 280 chars. Use a harmonious, supportive, elegant tone that resonates with beauty and balance. No hashtag spam.
"""


class SocialMediaAgent(BasePolsiaAgent):
    agent_type = "social_media"
    default_model = "claude-haiku-4-5-20251001"

    def run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        context_str = build_context_prompt(context)
        prompt = f"""Company context:\n{context_str}\n\nTask: {task.get('title', 'Draft tweets')}
{task.get('description', '')}"""

        result = self.call_claude_json(prompt=prompt, system_prompt=SYSTEM_PROMPT)
        tweets = result.get("tweets", [])

        if settings.sandbox_mode:
            return {
                "summary": f"[SANDBOX] Drafted {len(tweets)} tweets (not posted)",
                "tweets": tweets,
                "posted": False,
            }

        posted = []
        try:
            import tweepy
            client = tweepy.Client(
                consumer_key=settings.twitter_api_key,
                consumer_secret=settings.twitter_api_secret,
                access_token=settings.twitter_access_token,
                access_token_secret=settings.twitter_access_secret,
            )
            for tweet in tweets[:1]:
                resp = client.create_tweet(text=tweet)
                posted.append({"text": tweet, "id": resp.data["id"]})
        except Exception as e:
            return {"summary": f"Twitter error: {e}", "tweets": tweets, "posted": False}

        return {
            "summary": f"Posted {len(posted)} tweet(s)",
            "tweets": tweets,
            "posted_tweets": posted,
            "posted": True,
        }
