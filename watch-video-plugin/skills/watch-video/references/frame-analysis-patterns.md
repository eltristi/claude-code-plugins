# Frame Analysis Patterns

## Screen Recordings & Bug Reports

When analyzing screen recordings (common in development workflows):

### What to look for:
- **Error messages**: Red text, toast notifications, modal dialogs with error content
- **UI state changes**: Buttons becoming disabled, loading spinners, layout shifts
- **Console output**: If dev tools are visible, note any errors or warnings
- **Navigation**: Track which pages/screens are visited and in what order
- **User actions**: Click targets, form inputs, scroll behavior
- **Timing issues**: Flickers, race conditions visible as brief incorrect states

### Output format for bug reports:
```
## Video Analysis: [filename]

### Summary
[1-2 sentence overview of what the recording shows]

### Timeline
- **0:00-0:05** — [Starting state description]
- **0:06** — [User action: clicks X]
- **0:07-0:10** — [Result of action]
- **0:11** — [Bug occurs: description]

### Observed Issues
1. **[Issue name]** (at 0:11): [Description of what went wrong]
   - Expected: [What should happen]
   - Actual: [What happened]

### Environment Clues
- Browser/OS visible: [if identifiable]
- Screen resolution: [from video dimensions]
- Dark/light mode: [if identifiable]
```

## Presentations & Slides

When analyzing slide-based content:

### Extraction strategy:
- Use scene detection (`select='gt(scene,0.4)'`) — slides have clear transitions
- Each scene change likely represents a new slide
- Lower density needed between transitions

### What to extract:
- Slide titles and headings
- Key bullet points and text content
- Diagrams and charts (describe visually)
- Speaker notes if visible
- Slide numbers for reference

### Output format:
```
## Presentation Analysis: [filename]

### Overview
[Topic, apparent audience, total slides]

### Slide-by-slide Summary
1. **Title Slide** (0:00) — [Title, presenter, date if visible]
2. **[Slide title]** (0:45) — [Key points]
3. **[Slide title]** (1:30) — [Key points, describe any diagrams]
...

### Key Takeaways
- [Main point 1]
- [Main point 2]
```

## Tutorial / Walkthrough Videos

When analyzing instructional content:

### Extraction strategy:
- Higher density (1-2 fps) during action sequences
- Lower density during explanation pauses
- Multi-pass: overview first, then detail on complex steps

### What to extract:
- Step-by-step instructions shown
- Code being typed or edited
- Terminal commands and their output
- File/folder structures shown
- Configuration settings demonstrated

### Output format:
```
## Tutorial Analysis: [filename]

### Topic
[What the tutorial teaches]

### Prerequisites
[Any tools, accounts, or knowledge mentioned]

### Steps
1. **[Step name]** (0:00-1:30)
   - [Action description]
   - Code/command: `[if visible]`

2. **[Step name]** (1:31-3:00)
   - [Action description]
   - Important note: [any warnings or tips shown]

### Final Result
[What the completed tutorial produces]
```

## UI/UX Review Videos

When analyzing design review or user testing recordings:

### What to look for:
- Navigation flow and user journey
- Interaction patterns (hover states, transitions, animations)
- Responsive behavior if screen resizes
- Accessibility indicators (focus rings, screen reader, contrast)
- Performance issues (jank, slow loads, layout shifts)

### Output format:
```
## UI Review: [filename]

### Flow Analyzed
[Description of the user journey shown]

### Observations
| Timestamp | Screen/Component | Observation | Severity |
|-----------|------------------|-------------|----------|
| 0:05 | Login page | [observation] | Info/Warning/Issue |

### UX Findings
- **Positive**: [What works well]
- **Issues**: [What needs improvement]
- **Suggestions**: [Concrete improvements]
```

## Real-world / Camera Footage

When analyzing non-screen content (product demos, physical events):

### Extraction strategy:
- Scene detection works well for varied content
- 0.5-1 fps for continuous action
- Higher density for fast-moving content

### What to describe:
- Setting and environment
- People and their actions (without identifying individuals)
- Objects and products shown
- Text visible in the environment (signs, labels, screens)
- Sequence of events chronologically

## Multi-pass Deep Analysis

For any video type requiring detailed analysis:

### Pass 1: Overview (sparse)
- Extract at 0.1-0.2 fps (1 frame per 5-10 seconds)
- Read all frames quickly
- Identify major segments and transitions
- Note timestamps of interest

### Pass 2: Detail (targeted)
- For each segment of interest, re-extract at 2-3 fps
- Use ffmpeg time range: `ffmpeg -ss <start> -to <end> -i <video> -vf "fps=3" ...`
- Analyze frames closely for the specific question or concern

### Pass 3: Verification (optional)
- If findings are ambiguous, extract specific single frames
- Use: `ffmpeg -ss <exact_time> -i <video> -frames:v 1 <output>.jpg`
- Confirm observations from earlier passes
