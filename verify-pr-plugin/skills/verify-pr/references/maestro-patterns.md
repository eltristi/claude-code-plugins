# Maestro Flow Patterns

Reference for generating Maestro YAML flows. Consult when generating flows for Expo projects.

## Basic Structure

```yaml
appId: com.example.myapp
---
- launchApp
```

Every flow starts with the `appId` header and `launchApp`.

## Common Actions

### Tap on Element

```yaml
# By text
- tapOn: "Login"

# By ID (testID in React Native)
- tapOn:
    id: "login-button"

# By index when multiple matches
- tapOn:
    text: "Submit"
    index: 0
```

### Input Text

```yaml
- tapOn:
    id: "email-input"
- inputText: "user@example.com"

# Clear field first
- tapOn:
    id: "email-input"
- eraseText: 50
- inputText: "new-value"
```

### Scroll

```yaml
# Scroll down
- scroll

# Scroll until element visible
- scrollUntilVisible:
    element:
      text: "Save"
    direction: DOWN
    timeout: 10000
```

### Assertions

```yaml
# Element is visible
- assertVisible: "Welcome"
- assertVisible:
    id: "dashboard-header"

# Element not visible
- assertNotVisible: "Error"

# Wait for element (with timeout)
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: 10000
```

### Navigation (Back)

```yaml
- back
```

### Wait

```yaml
# Wait fixed time (ms)
- waitForAnimationToEnd

# Wait for element
- extendedWaitUntil:
    visible: "Loaded"
    timeout: 5000
```

### Swipe

```yaml
- swipe:
    direction: LEFT
    duration: 500

# Swipe on specific element
- swipe:
    direction: UP
    element:
      id: "scroll-view"
```

## Login Flow Pattern

```yaml
appId: com.example.myapp
---
- launchApp
- tapOn:
    id: "email-input"
- inputText: "${EMAIL}"
- tapOn:
    id: "password-input"
- inputText: "${PASSWORD}"
- tapOn: "Log In"
- extendedWaitUntil:
    visible: "Home"
    timeout: 10000
```

Run with env variables: `maestro record -e EMAIL=test@test.com -e PASSWORD=secret flow.yaml`

## Form Submission Pattern

```yaml
- tapOn:
    id: "name-input"
- inputText: "John Doe"
- tapOn:
    id: "email-input"
- inputText: "john@example.com"
- tapOn: "Submit"
- assertVisible: "Success"
```

## Navigation Pattern

```yaml
- launchApp
- tapOn: "Settings"
- assertVisible: "Settings"
- tapOn: "Profile"
- assertVisible: "Edit Profile"
- back
- assertVisible: "Settings"
```

## Tab Navigation Pattern

```yaml
- launchApp
- tapOn:
    id: "tab-home"
- assertVisible: "Home"
- tapOn:
    id: "tab-search"
- assertVisible: "Search"
```

## Modal / Bottom Sheet Pattern

```yaml
- tapOn: "Show Details"
- assertVisible: "Detail Modal"
- tapOn: "Close"
- assertNotVisible: "Detail Modal"
```

## Pull to Refresh Pattern

```yaml
- swipe:
    direction: DOWN
    element:
      id: "list-view"
    duration: 1000
- waitForAnimationToEnd
```

## Tips for Flow Generation

- Prefer `id` selectors (maps to `testID` in React Native) over text when available
- When `testID` is not set, use visible text content
- Add `waitForAnimationToEnd` after navigation transitions
- Use `extendedWaitUntil` for async operations (API calls, loading states)
- Keep flows short and focused — one scenario per flow
- Use environment variables for credentials: `${VARIABLE_NAME}`
