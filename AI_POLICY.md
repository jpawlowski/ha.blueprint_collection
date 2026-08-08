# Community AI Development Policy

This project supports the use of AI tools in the development of Home Assistant blueprints. AI-assisted
development can make useful blueprints possible when a contributor would otherwise lack the time or specialized
knowledge to build them.

## Scope

Home Assistant blueprints, shared by URL import and through the community Blueprint Exchange, are community
projects. They are not part of Home Assistant Core and are not automatically subject to the contribution rules of
the Open Home Foundation (OHF).
Core policies may still provide valuable guidance, but this project does not assume that every restriction appropriate
for Core is also appropriate for an independently maintained community blueprint collection.

If code from this project is contributed to an OHF repository, the current
[OHF AI Policy](https://developers.home-assistant.io/docs/ai_policy/) applies to that contribution.

## AI use is welcome

AI tools may be used for any part of development, including research, implementation, tests, documentation, review,
and project initialization. A blueprint may be substantially or predominantly AI-generated. This project values a
useful, inspectable attempt to solve a community problem over requiring that every project could have been completed
without AI.

AI assistance does not by itself determine software quality. Handwritten and AI-generated code are held to the same
automated checks and quality standards provided by this repository.

## Transparency enables informed decisions

Users choose whether to import a blueprint and accept the associated risk. Maintainers must not create a
misleading impression of a blueprint's maturity or level of verification. When relevant, project documentation
should distinguish between:

- the extent of AI assistance;
- the extent of human code review and maintainer understanding;
- automated test coverage and results;
- testing with real devices or services;
- known limitations, untested areas, and security-sensitive uncertainty; and
- the blueprint's maturity, such as experimental, beta, or stable.

AI usage, human review, automated testing, and real-world testing are separate facts. Passing linters or tests must not
be presented as proof that a maintainer fully understands the code, and extensive AI use must not be presented as proof
that the code is low quality.

## Maintainer responsibility

Maintainers are encouraged to understand and oversee as much of their collection as reasonably possible, especially
when sharing it publicly. They remain responsible for honestly documenting what they have and have not
reviewed or tested, responding to safety and security concerns, and avoiding unsupported claims about reliability.

Where complete manual review is impractical, stronger indirect safeguards become more important. These include focused
modules, type checking, linting, Home Assistant validation, automated tests for important behavior and regressions, and
real-device testing where available. Automated checks reduce risk; they do not eliminate it.

## Agents and publication

AI agents may prepare local changes, draft pull requests, release notes, issue drafts, and suggested review responses in
repositories whose maintainers permit that workflow. A human should review material before publishing or merging it and
must follow the rules of the destination project. Agents must not represent their output as human-reviewed or tested
when that has not occurred.

Deterministic automation such as dependency updates, release workflows, and template synchronization is not treated as
AI authorship merely because it opens a pull request. Its output should still be reviewed according to the risk of the
change.

## Purpose of this blueprint

This blueprint helps both humans and AI agents work at a useful level of abstraction. Its prescribed architecture,
small modules, type hints, validation scripts, and Home Assistant patterns are intended to make generated code easier
to inspect and verify. They are safeguards, not a guarantee of correctness or a substitute for transparent maintenance.
