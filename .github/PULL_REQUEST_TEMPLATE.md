## What does this PR do?

<!-- One sentence describing the change -->

## Type of change

- [ ] New skill
- [ ] Skill improvement
- [ ] Bug fix
- [ ] Documentation
- [ ] Config / setup

## Testing

- [ ] Frontmatter validates (`head -20 */SKILL.md | grep "^name:"`)
- [ ] Setup script runs without errors (`bash setup`)
- [ ] Skill invocation tested in Claude Code
- [ ] Config read/write works (if config changes)

## Checklist

- [ ] Follows [CONTRIBUTING.md](../CONTRIBUTING.md) conventions
- [ ] No credentials or API keys committed
- [ ] Work products go at project root, plumbing in `.rstack/`
- [ ] Human checkpoints at every phase boundary (if new/modified skill)
- [ ] `WebSearch` included in `allowed-tools` if skill needs web access
