# Version-matched Next.js references

Use this guide to locate framework facts; do not copy its behavior summaries into architecture decisions. Resolve documentation from the Next.js package actually used by the app being changed. In a monorepo, resolve from that app/package, not blindly from the workspace root. Do not use a machine-specific global path.

## Resolution order

1. Inspect the app’s package manifest and lockfile to learn the installed/resolved Next.js version.
2. Resolve the `next` package root with the project’s package manager/runtime, accounting for workspace layouts and package-manager symlinks.
3. If the installed package contains `dist/docs/`, search the relevant `01-app/` guide/API page there. The package documentation is version-coupled to that installation.
4. If it is absent or incomplete, use [official Next.js documentation](https://nextjs.org/docs) and verify the page matches the installed major/minor behavior. Use upgrade/migration docs when the task changes versions.
5. If neither source answers the question, state the uncertainty and avoid presenting a remembered or inferred behavior as verified.

The projects examined for this skill had `next` 16.3.1 and 16.3.4. Both installed packages contained the following `dist/docs/01-app/` paths. These are verified examples of package-relative locations, not absolute paths to copy into an agent config. Package documentation may move between versions; search the installed docs when a listed path does not exist.

## Topic map

| Question | Package-relative docs to consult |
| --- | --- |
| App Router structure, layouts, pages, route groups, params | `01-app/01-getting-started/02-project-structure.md`; `01-app/01-getting-started/03-layouts-and-pages.md`; `01-app/03-api-reference/03-file-conventions/route-groups.md` |
| Server vs Client Components and boundary safety | `01-app/01-getting-started/05-server-and-client-components.md`; `01-app/02-guides/server-and-client-boundary.md` |
| Server-side data reads | `01-app/01-getting-started/06-fetching-data.md`; `01-app/02-guides/data-security.md` |
| Mutations and Server Actions/Functions | `01-app/01-getting-started/07-mutating-data.md`; `01-app/02-guides/server-actions.md`; `01-app/03-api-reference/01-directives/use-server.md` |
| Cache Components and `use cache` | `01-app/01-getting-started/08-caching.md`; `01-app/03-api-reference/01-directives/use-cache.md`; relevant `cacheComponents`, `cacheLife`, and `cacheTag` API pages |
| Revalidation/invalidation semantics | `01-app/01-getting-started/09-revalidating.md`; `01-app/02-guides/how-revalidation-works.md`; `01-app/03-api-reference/04-functions/revalidatePath.md`; `revalidateTag.md`; `updateTag.md` when present |
| Errors, redirects, not-found, control flow | `01-app/01-getting-started/10-error-handling.md`; `01-app/03-api-reference/04-functions/redirect.md`; `01-app/03-api-reference/04-functions/not-found.md`; `01-app/03-api-reference/04-functions/permanentRedirect.md` |
| Route Handlers and request/response boundaries | `01-app/01-getting-started/15-route-handlers.md`; `01-app/03-api-reference/03-file-conventions/route.md` |
| Middleware/proxy and runtime support | `01-app/01-getting-started/16-proxy.md`; `01-app/03-api-reference/03-file-conventions/proxy.md`; `01-app/03-api-reference/03-file-conventions/02-route-segment-config/runtime.md`; Edge/runtime guides |
| Authentication and authorization guidance | `01-app/02-guides/authentication.md`; `authentication-with-cache-components.md`; `data-security.md` |
| Security headers/content policy | `01-app/02-guides/content-security-policy.md`; `data-security.md`; production checklist |
| Production/performance practices | `01-app/02-guides/production-checklist.md`; `01-app/02-guides/third-party-libraries.md`; `01-app/03-api-reference/04-functions/use-report-web-vitals.md`. The inspected package did not include a dedicated package-bundling guide; if absent in the target version too, consult the [official Package Bundling guide](https://nextjs.org/docs/app/guides/package-bundling) and verify its recommendations against that installed version. |

The names above are an index, not a substitute for reading the topic page. Caching, rendering, streaming, action, runtime, and performance details are particularly version-sensitive. The Next.js skill adds feature ownership and application-layer integration; it does not restate those framework mechanics.

## Project notes and version-specific findings

If a project has a verified issue/workaround (for example, a proxy file that compiles but does not execute with a specific runtime/provider/toolchain), keep it in that project’s `.fs-skills/conventions/` or architecture decision. Record the exact framework/provider versions, how behavior was verified, date, and a condition for rechecking. Do not turn a local incident into a universal rule. Reverify after dependency/runtime upgrades instead of trusting an old `AGENTS.md` note or this reference map.
