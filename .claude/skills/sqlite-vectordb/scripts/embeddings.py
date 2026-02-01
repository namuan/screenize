"""Embedding generation utilities."""

import sys
from functools import lru_cache

import numpy as np

from config import EMBEDDING_MODEL


@lru_cache(maxsize=1)
def get_model():
    """Load and cache the sentence transformer model."""
    try:
        from sentence_transformers import SentenceTransformer
        return SentenceTransformer(EMBEDDING_MODEL)
    except ImportError:
        print("Error: sentence-transformers not installed.", file=sys.stderr)
        sys.exit(3)


def generate_embedding(text: str) -> np.ndarray:
    """Generate embedding for text."""
    model = get_model()
    embedding = model.encode(text, convert_to_numpy=True)
    return embedding.astype(np.float32)


def generate_embeddings(texts: list[str]) -> list[np.ndarray]:
    """Generate embeddings for multiple texts."""
    model = get_model()
    embeddings = model.encode(texts, convert_to_numpy=True)
    return [e.astype(np.float32) for e in embeddings]
