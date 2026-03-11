# Playwright Test Patterns

Reference for generating Playwright test scripts with video recording. Consult when generating flows for Laravel web projects.

## Basic Structure with Video Recording

```typescript
import { test, expect } from '@playwright/test';

test.use({
  video: 'on',
  baseURL: 'http://localhost:8080',
});

test('scenario name', async ({ page }) => {
  await page.goto('/');
  // ... test steps
});
```

## Playwright Config for Video

When generating tests, create a `playwright.config.ts` in `/tmp/pr-verify-flows/`:

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '/tmp/pr-verify-flows',
  testMatch: 'pr-*.spec.ts',
  timeout: 180000, // 3 min per test
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:8080',
    video: 'on',
    screenshot: 'on',
    trace: 'on-first-retry',
  },
  outputDir: '/tmp/pr-verify-flows/test-results',
});
```

## Common Actions

### Navigation

```typescript
await page.goto('/dashboard');
await page.goto('/users/123');
```

### Click

```typescript
// By text
await page.getByText('Submit').click();

// By role
await page.getByRole('button', { name: 'Save' }).click();

// By test ID
await page.getByTestId('save-button').click();

// By CSS selector
await page.locator('.submit-btn').click();
```

### Fill Input

```typescript
// By label
await page.getByLabel('Email').fill('user@example.com');

// By placeholder
await page.getByPlaceholder('Enter email').fill('user@example.com');

// By test ID
await page.getByTestId('email-input').fill('user@example.com');
```

### Select Dropdown

```typescript
await page.getByLabel('Country').selectOption('us');
```

### Assertions

```typescript
// Element visible
await expect(page.getByText('Welcome')).toBeVisible();

// Element not visible
await expect(page.getByText('Error')).not.toBeVisible();

// Page URL
await expect(page).toHaveURL('/dashboard');

// Page title
await expect(page).toHaveTitle('Dashboard');

// Element has text
await expect(page.getByTestId('status')).toHaveText('Active');
```

### Wait for Element

```typescript
// Wait for element to appear
await page.getByText('Loaded').waitFor({ state: 'visible', timeout: 10000 });

// Wait for navigation
await page.waitForURL('/dashboard');

// Wait for network idle
await page.waitForLoadState('networkidle');
```

## Login Flow Pattern

```typescript
test('login', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.TEST_EMAIL || 'test@example.com');
  await page.getByLabel('Password').fill(process.env.TEST_PASSWORD || 'password');
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForURL('/dashboard');
  await expect(page.getByText('Dashboard')).toBeVisible();
});
```

## Authenticated Test Pattern

Combine login with the actual test:

```typescript
test('edit profile (authenticated)', async ({ page }) => {
  // Login first
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.TEST_EMAIL!);
  await page.getByLabel('Password').fill(process.env.TEST_PASSWORD!);
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForURL('/dashboard');

  // Now test the feature
  await page.goto('/profile/edit');
  await page.getByLabel('Name').fill('Updated Name');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Profile updated')).toBeVisible();
});
```

## Form Submission Pattern

```typescript
test('create new item', async ({ page }) => {
  await page.goto('/items/create');
  await page.getByLabel('Name').fill('Test Item');
  await page.getByLabel('Description').fill('A test description');
  await page.getByLabel('Category').selectOption('electronics');
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByText('Item created successfully')).toBeVisible();
});
```

## Table / List Interaction Pattern

```typescript
test('view and interact with table', async ({ page }) => {
  await page.goto('/users');
  await page.waitForLoadState('networkidle');

  // Click on a row
  await page.getByRole('row').filter({ hasText: 'John Doe' }).click();
  await expect(page).toHaveURL(/\/users\/\d+/);
});
```

## Modal Pattern

```typescript
test('open and interact with modal', async ({ page }) => {
  await page.goto('/items');
  await page.getByRole('button', { name: 'Delete' }).first().click();

  // Interact with modal
  const modal = page.getByRole('dialog');
  await expect(modal).toBeVisible();
  await modal.getByRole('button', { name: 'Confirm' }).click();
  await expect(modal).not.toBeVisible();
});
```

## File Upload Pattern

```typescript
test('upload file', async ({ page }) => {
  await page.goto('/upload');
  const fileInput = page.getByLabel('Choose file');
  await fileInput.setInputFiles('/path/to/test-file.pdf');
  await page.getByRole('button', { name: 'Upload' }).click();
  await expect(page.getByText('File uploaded')).toBeVisible();
});
```

## Tips for Flow Generation

- Prefer `getByRole`, `getByLabel`, `getByText` over CSS selectors — more resilient
- Use `getByTestId` when available (maps to `data-testid` attribute)
- Always `waitForLoadState('networkidle')` after navigation to pages with API calls
- Use `process.env` for credentials — never hardcode
- Set `video: 'on'` in test config to capture recordings
- Videos are saved to `outputDir/test-name/video.webm`
- Keep tests focused — one scenario per file
- Add `await page.waitForTimeout(500)` sparingly for visual recording clarity (animations)
