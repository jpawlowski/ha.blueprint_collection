# Templating in Blueprints

Read this before writing any Jinja inside a blueprint.

## Prefer no template at all

Templates bypass load-time validation and fail at runtime, usually silently, usually on
someone else's instance. Before writing one, check
[triggers-conditions.md](triggers-conditions.md) for a native trigger or condition that
expresses the same thing. Most template conditions in the wild are a `numeric_state`
condition nobody looked for.

Templates are appropriate for: computing a value from several inputs, formatting a
notification message, and availability expressions in template blueprints.

## `!input` is a YAML tag, not a template value

This is the single most common blueprint bug.

```yaml
# ❌ Does not work. !input is resolved by the YAML loader, not by Jinja.
message: "Sensor is {{ states(!input my_sensor) }}"

# ✅ Bind to a variable first, then use the variable
variables:
  my_sensor: !input my_sensor
# ...
message: "Sensor is {{ states(my_sensor) }}"
```

The variable name may match the input name — that is the convention here, and it keeps
the mapping obvious.

**Where `variables:` goes:**

- `automation` — a top-level `variables:` block, or a `variables:` step inside `actions:`
- `script` — top-level `variables:`, or per-step
- `template` — top-level `variables:`, available to every entity expression

A `variables:` **step** inside a sequence is evaluated when that step runs, so it can read
state that earlier steps changed. A top-level `variables:` block is evaluated once at the
start of the run.

## `trigger_variables:` is a limited template context

`trigger_variables:` exists to feed `!input` values into trigger options that need them
before the trigger fires. It supports **limited templates only**:

```yaml
trigger_variables:
  my_event: !input event_type # ✅ binding an input


# ❌ Not available here — no state machine access at this point
#   states(), is_state(), state_attr(), expand(), now()
```

Anything that needs state belongs in an action-scope `variables:` block or a condition.

## Guard optional entity inputs

The idiom for an optional entity input is `default: []`. That means every use of it must
be guarded, in **every** context — including trigger templates and availability
expressions:

```yaml
variables:
  lux_sensor: !input lux_sensor # selector entity, default: []

conditions:
  - condition: template
    value_template: >-
      {{ lux_sensor == [] or states(lux_sensor) | float(0) < threshold }}
```

`states([])` does not return `unknown` — it raises, and the whole template fails.

## Booleans must be a single expression

A `{% if %}` block that "returns" a bare `false` produces the **string** `"false"`, which
is truthy. Home Assistant's literal-eval pass does not save you here.

```yaml
# ❌ renders the string "false" → truthy
allow_run: >-
  {% if some_condition %}true{% else %}false{% endif %}

# ✅ one expression, real boolean
allow_run: "{{ some_condition and other_condition }}"
```

Multi-branch `{% if %}` blocks are fine for variables consumed as strings or numbers.

## Default everything that can be unavailable

Entities are `unavailable` or `unknown` more often than authors assume — at startup, after
an integration reload, when a battery device drops off.

```yaml
{{ states(my_sensor) | float(0) }}          # never bare | float
{{ state_attr(my_light, 'brightness') | int(0) }}
{{ states(my_sensor) | default('unknown') }}
```

`has_value(entity)` is the readable check for "this entity has a usable state" and is what
belongs in a template blueprint's `availability:`.

## Template blueprint availability

A template entity without an `availability:` expression turns into a garbage state when its
source is missing, and that garbage propagates into everything downstream.

```yaml
variables:
  reference_entity: !input reference_entity

binary_sensor:
  state: "{{ states(reference_entity) == 'off' }}"
  availability: "{{ has_value(reference_entity) }}"
```

## Variables render in key order, one at a time

Within a single `variables:` block each key is rendered in order, so a key cannot reference
one declared below it. The error is an undefined variable, not an obvious ordering complaint.

```yaml
# ❌ total is still undefined when msg renders
variables:
  msg: "Total: {{ total }}"
  total: "{{ a | int + b | int }}"

# ✅ declare before use
variables:
  total: "{{ a | int + b | int }}"
  msg: "Total: {{ total }}"
```

## Performance

A **state-based** template re-renders whenever _any_ entity it references changes — including
entities read only inside an `{% if %}` branch that is currently false. In a blueprint that
cost is multiplied by every user who imports it.

- Keep expensive work out of `state:`. `expand()` over a large group, nested loops, and
  repeated `states()` calls on the same entity all run on every source change.
- Assign a value used more than once to a variable instead of calling `states()` repeatedly.
- If the template is genuinely expensive, make the template blueprint **trigger-based** —
  see [domains.md](domains.md).

## Cheap safety idioms

Worth applying by reflex, because the failure mode is a broken entity on someone else's
instance:

```yaml
{{ states(x) | float(0) }}                    # never a bare | float
{{ state_attr(x, 'brightness') | int(0) }}    # attributes are None more often than you think
{{ states(x) not in ['unknown', 'unavailable', 'none'] }}   # explicit validity check
{{ has_value(x) }}                            # the readable form of the same check
{{ (state_attr(x, 'items') or []) | count }}  # None-safe before a filter
{{ x | default(3) }}                          # undefined-safe — | int(3) is NOT
```

The last line is the one that surprises people: `| int(3)` supplies a fallback for a value
that exists but will not convert. It does **not** cover an undefined variable — only
`| default()` does. This is why script blueprint `fields:` need `| default()`; see pitfall W
in [pitfalls.md](pitfalls.md).

## Useful in blueprints specifically

| Expression                                      | Use                                                     |
| ----------------------------------------------- | ------------------------------------------------------- |
| `expand(my_target_input)`                       | Iterate the entities behind a `target`, including areas |
| `area_entities(area)` / `label_entities(label)` | Resolve an area/label input to entity ids               |
| `device_entities(device_id)`                    | Only when a `device` selector was genuinely necessary   |
| `iif(cond, a, b)`                               | Inline choice without an `{% if %}` block               |
| `as_timestamp(now())`                           | Time maths; never store `now()` in a top-level variable |
| `trigger.entity_id` / `trigger.to_state`        | Which entity fired, inside actions                      |
| `this.entity_id`                                | The automation/script's own entity                      |

**Never put `now()` in a top-level `variables:` block.** With a delay in the sequence the
value is stale by the time it is read. Compute it at the point of use.

## Debugging a template

`Developer Tools → Template` evaluates against the live state machine. It cannot resolve
`!input`, so paste the template with the input's real value substituted — which is exactly
what the `variables:` binding makes easy.

For anything trigger-dependent, use the automation trace instead: it shows
`changed_variables` per step, including every rendered template. See
[debugging.md](debugging.md).

## Reference

- [Templating](https://www.home-assistant.io/docs/configuration/templating/)
- [Debugging templates](https://www.home-assistant.io/docs/templating/debugging/)
- [Template integration](https://www.home-assistant.io/integrations/template/)
