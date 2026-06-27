"""Bellek seed spatial testleri."""

import pytest

from services.memory_spatial import memory_query


def test_kadikoy_seed_hit():
    result = memory_query(40.9927, 29.0277)
    assert result is not None
    assert result.parcel is not None
    assert result.parcel.ada == "1234"
    assert result.zoning is not None
    assert result.zoning.taks == 0.4


def test_outside_seed_returns_none():
    result = memory_query(41.5, 32.5)
    assert result is None
