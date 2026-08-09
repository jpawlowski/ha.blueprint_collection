"""Verify the editor JSON Schema against the real blueprints.

`schemas/json/blueprint_schema.json` powers completion and error highlighting in
the editor. It is a hand-written approximation of Home Assistant's own
`BLUEPRINT_SCHEMA`, so it can drift — and a drifted editor schema is worse than
none, because it marks correct blueprints as broken.

These tests pin both directions: every shipped blueprint must validate, and the
mistakes the schema exists to catch must still be caught.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from jsonschema import Draft7Validator
import pytest
import yaml

REPO_ROOT = Path(__file__).parent.parent
SCHEMA_PATH = REPO_ROOT / "schemas" / "json" / "blueprint_schema.json"
BLUEPRINTS_ROOT = REPO_ROOT / "blueprints"


class _BlueprintLoader(yaml.SafeLoader):
    """YAML loader that renders Home Assistant's !input tag as a plain string.

    JSON Schema has no concept of custom YAML tags. The editor's YAML extension
    resolves `!input` to a scalar too (it is registered in `yaml.customTags`),
    so this mirrors what the editor actually validates.
    """


def _construct_input(loader: _BlueprintLoader, node: yaml.ScalarNode) -> str:
    return f"!input {loader.construct_scalar(node)}"


_BlueprintLoader.add_constructor("!input", _construct_input)


@pytest.fixture(scope="module")
def validator() -> Draft7Validator:
    """Return a validator for the editor schema, checking the schema itself first."""
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    Draft7Validator.check_schema(schema)
    return Draft7Validator(schema)


def _blueprint_files() -> list[Path]:
    return sorted(BLUEPRINTS_ROOT.rglob("*.yaml"))


def test_blueprints_exist() -> None:
    """Guard against the parametrised test silently covering nothing."""
    assert _blueprint_files(), "no blueprints found under blueprints/"


@pytest.mark.parametrize("path", _blueprint_files(), ids=lambda p: p.stem)
def test_shipped_blueprint_validates(path: Path, validator: Draft7Validator) -> None:
    """Every blueprint in the collection must pass the editor schema."""
    data = yaml.load(path.read_text(encoding="utf-8"), Loader=_BlueprintLoader)
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    assert not errors, "\n".join(f"{list(e.path)}: {e.message}" for e in errors)


def _bp(**metadata: Any) -> dict[str, Any]:
    return {"blueprint": {"name": "X", "domain": "automation", **metadata}}


@pytest.mark.parametrize(
    ("label", "document"),
    [
        ("misspelled metadata key", _bp(sourceurl="https://example.com/x.yaml")),
        ("unknown domain", {"blueprint": {"name": "X", "domain": "sensor"}}),
        ("two-part min_version", _bp(homeassistant={"min_version": "2024.10"})),
        ("missing name", {"blueprint": {"domain": "automation"}}),
        ("missing domain", {"blueprint": {"name": "X"}}),
        ("selector as string", _bp(input={"a": {"selector": "entity"}})),
        ("selector with two types", _bp(input={"a": {"selector": {"entity": {}, "number": {}}}})),
        ("section without input", _bp(input={"s": {"collapsed": True}})),
        ("unknown key in input definition", _bp(input={"a": {"not_a_real_key": "x"}})),
        ("no blueprint block", {"triggers": []}),
    ],
)
def test_invalid_document_is_rejected(label: str, document: dict[str, Any], validator: Draft7Validator) -> None:
    """The mistakes this schema exists to catch must stay caught."""
    assert list(validator.iter_errors(document)), f"{label} was accepted"


@pytest.mark.parametrize(
    ("label", "document"),
    [
        ("input declared without a body", _bp(input={"a": None})),
        (
            "section with nested inputs",
            _bp(input={"s": {"name": "Advanced", "collapsed": True, "input": {"a": {"name": "A"}}}}),
        ),
        # The blueprint body is domain-specific and deliberately unconstrained;
        # Home Assistant's own schema allows extra top-level keys as well.
        ("free-form body keys", {**_bp(), "mode": "restart", "triggers": [], "actions": []}),
    ],
)
def test_valid_document_is_accepted(label: str, document: dict[str, Any], validator: Draft7Validator) -> None:
    """Valid constructs must not be rejected — a false positive is the worse failure."""
    errors = list(validator.iter_errors(document))
    assert not errors, f"{label} was rejected: {errors[0].message if errors else ''}"
