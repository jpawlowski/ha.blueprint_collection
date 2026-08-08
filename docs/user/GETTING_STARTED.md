# Getting Started

This guide explains how to use the blueprints in this collection. You do not need to write any YAML.

## What is a blueprint?

A blueprint is a reusable, pre-built automation, script, or template entity. Instead of building an automation
from scratch, you import a blueprint once and then create automations from it by filling in a short form —
which light, which sensor, how long to wait.

The same blueprint can be used many times with different settings. Each automation you create from it is
independent.

## Requirements

Home Assistant **2024.10.0** or newer. Individual blueprints may require a newer version; each one states its
minimum in the import dialog.

## Importing a blueprint

### Option A: One-click (recommended)

Click the **Import Blueprint** badge next to any blueprint in the [README](../../README.md). Home Assistant opens
the import dialog with the blueprint already filled in — review it and click **Preview blueprint**, then
**Import blueprint**.

### Option B: Paste the URL

1. Go to **Settings > Automations & scenes > Blueprints**
2. Click **Import blueprint** (bottom right)
3. Paste the blueprint's GitHub URL
4. Click **Preview blueprint**, then **Import blueprint**

## Creating an automation from a blueprint

1. Go to **Settings > Automations & scenes > Blueprints**
2. Find the blueprint and click **Create automation** (script blueprints show **Add script**)
3. Fill in the inputs:
   - Fields **without** a default are required
   - Fields **with** a default can be left alone — the shown value is what will be used
   - Entity pickers are filtered to the relevant kinds of entity, so you cannot pick something unusable
4. Give it a name and click **Save**

You can create as many automations from one blueprint as you like — one per room, for example.

## Template blueprints

Template blueprints create **entities** rather than automations. Import them the same way, then go to
**Settings > Devices & services > Helpers > Create helper > Template > (blueprint name)**. You provide a name for
the new entity in addition to the blueprint's inputs.

## Changing settings later

**Settings > Automations & scenes**, open the automation, click **⋮ > Edit in visual editor** — you get the same
input form back. Changes take effect immediately after saving.

## Updating a blueprint

Home Assistant does **not** update imported blueprints automatically.

1. Go to **Settings > Automations & scenes > Blueprints**
2. Click **⋮** next to the blueprint → **Re-import blueprint**
3. Confirm

All automations created from that blueprint immediately use the updated version. Your input settings are kept —
unless the update renamed or removed an input, which the [release notes](../../README.md) will tell you.

> [!TIP]
> Check the release notes before re-importing. Breaking changes are always called out there.

## Removing a blueprint

You must delete every automation and script created from a blueprint before Home Assistant lets you delete the
blueprint itself. It will tell you which ones are still using it.

## Troubleshooting

**The automation does not trigger.** Open **Settings > Automations > (your automation) > Traces**. The trace
shows each step, which condition stopped the run, and the values involved — this answers most questions on its
own.

**The automation is stuck.** Automations that wait (for motion to clear, for a delay) show as running until they
finish. That is normal. If it is genuinely stuck, click **Run actions** → **Stop**.

**I picked the wrong entity.** Edit the automation in the visual editor and change the input.

**Something is actually broken.** [Open an issue](../../README.md) and include:

- Which blueprint and your Home Assistant version
- What you expected and what happened
- The automation trace (**Traces** → **Download trace**)

## Learn more

- [Home Assistant blueprint documentation](https://www.home-assistant.io/docs/blueprint/)
- [Blueprint Exchange forum](https://community.home-assistant.io/c/blueprints-exchange/53)
