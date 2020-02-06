"""Tests for `qalgebra` package."""

import pytest
from pkg_resources import parse_version

import qalgebra


def test_valid_version():
    """Check that the package defines a valid ``__version__``."""
    v_curr = parse_version(qalgebra.__version__)
    v_orig = parse_version("0.2.0-dev")
    assert v_curr >= v_orig
