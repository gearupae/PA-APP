"""Placeholder secret storage — replace with Fernet/KMS in Phase 5."""

import base64


def encrypt_placeholder(plain: str) -> str:
    encoded = base64.urlsafe_b64encode(plain.encode("utf-8")).decode("ascii")
    return f"enc:v1:{encoded}"


def decrypt_placeholder(blob: str) -> str:
    if not blob.startswith("enc:v1:"):
        raise ValueError("Unsupported ciphertext format")
    raw = base64.urlsafe_b64decode(blob.removeprefix("enc:v1:").encode("ascii"))
    return raw.decode("utf-8")
