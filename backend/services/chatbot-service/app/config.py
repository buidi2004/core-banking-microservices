import os
from pathlib import Path
from typing import List

try:
    from pydantic_settings import BaseSettings
    class Settings(BaseSettings):
        DATABASE_URL: str = os.getenv(
            "DATABASE_URL",
            "postgresql://chatbot_db_user:ChatbotDb#Secure2025!@postgres-chatbot:5432/ewallet_chatbot_db"
        )
        WALLET_SERVICE_URL: str = os.getenv(
            "WALLET_SERVICE_URL",
            "http://wallet-service:8082"
        )
        PAYMENT_SERVICE_URL: str = os.getenv(
            "PAYMENT_SERVICE_URL",
            "http://payment-service:8083"
        )
        IDENTITY_SERVICE_URL: str = os.getenv(
            "IDENTITY_SERVICE_URL",
            "http://identity-service:8081"
        )
        LLM_BASE_URL: str = os.getenv(
            "LLM_BASE_URL", 
            "https://generativelanguage.googleapis.com/v1beta/openai/"
        )
        LLM_API_KEY: str = os.getenv(
            "LLM_API_KEY", 
            os.getenv("GEMINI_API_KEY", os.getenv("OPENAI_API_KEY", ""))
        )
        LLM_BACKUP_API_KEY: str = os.getenv(
            "LLM_BACKUP_API_KEY", 
            ""
        )
        LLM_TERTIARY_API_KEY: str = os.getenv(
            "LLM_TERTIARY_API_KEY", 
            ""
        )
        LLM_MODEL: str = os.getenv("LLM_MODEL", "gemini-3.5-flash-lite")
        EMBED_MODEL: str = os.getenv("EMBED_MODEL", "intfloat/multilingual-e5-small")
        DATA_DIR: str = os.getenv(
            "DATA_DIR", 
            str(Path(__file__).resolve().parent.parent / "data")
        )
        TOP_K: int = int(os.getenv("TOP_K", "4"))
        MAX_DISTANCE: float = float(os.getenv("MAX_DISTANCE", "0.38"))
        INTERNAL_API_KEY: str = os.getenv(
            "INTERNAL_API_KEY", 
            "senhong-internal-chatbot-key-2026"
        )

        @property
        def api_keys(self) -> List[str]:
            keys: List[str] = []
            for k in [self.LLM_API_KEY, self.LLM_BACKUP_API_KEY, self.LLM_TERTIARY_API_KEY]:
                if k and k.strip() and k.strip() not in keys:
                    keys.append(k.strip())
            return keys

        class Config:
            env_file = ".env"
            extra = "ignore"
except ImportError:
    class Settings:
        DATABASE_URL: str = os.getenv(
            "DATABASE_URL",
            "postgresql://chatbot_db_user:ChatbotDb#Secure2025!@postgres-chatbot:5432/ewallet_chatbot_db"
        )
        WALLET_SERVICE_URL: str = os.getenv(
            "WALLET_SERVICE_URL",
            "http://wallet-service:8082"
        )
        PAYMENT_SERVICE_URL: str = os.getenv(
            "PAYMENT_SERVICE_URL",
            "http://payment-service:8083"
        )
        IDENTITY_SERVICE_URL: str = os.getenv(
            "IDENTITY_SERVICE_URL",
            "http://identity-service:8081"
        )
        LLM_BASE_URL: str = os.getenv(
            "LLM_BASE_URL", 
            "https://generativelanguage.googleapis.com/v1beta/openai/"
        )
        LLM_API_KEY: str = os.getenv(
            "LLM_API_KEY", 
            os.getenv("GEMINI_API_KEY", os.getenv("OPENAI_API_KEY", ""))
        )
        LLM_BACKUP_API_KEY: str = os.getenv(
            "LLM_BACKUP_API_KEY", 
            ""
        )
        LLM_TERTIARY_API_KEY: str = os.getenv(
            "LLM_TERTIARY_API_KEY", 
            ""
        )
        LLM_MODEL: str = os.getenv("LLM_MODEL", "gemini-3.5-flash-lite")
        EMBED_MODEL: str = os.getenv("EMBED_MODEL", "intfloat/multilingual-e5-small")
        DATA_DIR: str = os.getenv(
            "DATA_DIR", 
            str(Path(__file__).resolve().parent.parent / "data")
        )
        TOP_K: int = int(os.getenv("TOP_K", "4"))
        MAX_DISTANCE: float = float(os.getenv("MAX_DISTANCE", "0.38"))
        INTERNAL_API_KEY: str = os.getenv(
            "INTERNAL_API_KEY", 
            "senhong-internal-chatbot-key-2026"
        )

        @property
        def api_keys(self) -> List[str]:
            keys: List[str] = []
            for k in [self.LLM_API_KEY, self.LLM_BACKUP_API_KEY, self.LLM_TERTIARY_API_KEY]:
                if k and k.strip() and k.strip() not in keys:
                    keys.append(k.strip())
            return keys

settings = Settings()
