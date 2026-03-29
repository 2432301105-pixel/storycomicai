"""Domain/service layer exceptions."""

from __future__ import annotations


class DomainError(Exception):
    """Business error that maps to a controlled API response."""

    def __init__(self, code: str, message: str, status_code: int = 400) -> None:
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)

