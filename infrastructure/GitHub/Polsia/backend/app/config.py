from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    environment: str = "development"
    api_key: str = "polsia-unlocked-key"
    sandbox_mode: bool = False

    database_url: str = "postgresql+asyncpg://polsia:polsia_password@localhost:5432/polsia"

    redis_url: str = "redis://localhost:6379/0"
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/1"

    chroma_persist_dir: str = "/app/data/chroma"

    claude_cli_path: str = "claude"
    claude_cli_mock: str = ""
    claude_cli_mock_response: str = '{"result": "{\\"summary\\": \\"Mock generation complete\\"}"}'

    cerebellum_enabled: bool = True
    # Use local fish cerebellum routing for Ouroboros memory + governor model selection (lilith/grok-msn etc.)
    use_fish_cerebellum: bool = True
    cerebellum_url: str = "http://localhost:11434"
    cerebellum_model: str = "grok-msn"
    cerebellum_fallback: str = "hermes3:8b"

    twitter_api_key: str = ""
    twitter_api_secret: str = ""
    twitter_access_token: str = ""
    twitter_access_secret: str = ""
    twitter_bearer_token: str = ""

    google_ads_developer_token: str = ""
    google_ads_client_id: str = ""
    google_ads_client_secret: str = ""
    google_ads_refresh_token: str = ""
    google_ads_customer_id: str = ""

    meta_app_id: str = ""
    meta_app_secret: str = ""
    meta_access_token: str = ""
    meta_ad_account_id: str = ""

    sendgrid_api_key: str = ""
    sendgrid_from_email: str = "agent@yourcompany.com"
    imap_host: str = "imap.gmail.com"
    imap_user: str = ""
    imap_password: str = ""

    hunter_io_api_key: str = ""
    tavily_api_key: str = ""

    github_token: str = ""
    github_repo: str = ""
    vercel_token: str = ""
    railway_api_key: str = ""

    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    stripe_publishable_key: str = ""

    morning_cycle_hour: int = 6
    evening_cycle_hour: int = 20


settings = Settings()
