# GateX

A lightweight API gateway for microservices, built on Spring Cloud Gateway. It routes client requests to downstream services, injects a trace ID into every request, logs traffic, and enforces per-route timeouts.

**Stack:** Java 21, Spring Boot 3.3.4, Spring Cloud 2023.0.3, Spring Cloud Gateway, Actuator, Maven, Azure App Service

**Live deployment:** https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net

## Features

| Requirement | What it does |
|-------------|--------------|
| FR-1 Routing | Forwards `/api/users/**` to UserService and `/api/reports/**` to ReportService. |
| FR-2 Logging | Gateway and Netty request logging, controlled in `application.yaml`. |
| FR-3 Trace ID | `CorrelationIdFilter` reuses the caller's `X-Correlation-Id` or generates one, forwards it downstream and returns it in the response. |
| Resiliency | The reports route has a 3 second connect and response timeout. A slower service gives the client a 504. |

## Routes

| Client path | Downstream | Notes |
|-------------|------------|-------|
| `/api/users/**` | UserService | `StripPrefix=1`, so `/api/users/1` reaches the service as `/users/1`. |
| `/api/reports/**` | ReportService | No prefix stripping. The service itself serves `/api/reports/...`. |

## Run locally

```
mvn spring-boot:run
```

GateX listens on port 8082 by default. The route targets are the deployed mock services configured in `application.yaml`.

## Try it

The examples below use the live Azure deployment. To test a local run instead, replace the base URL with `http://localhost:8082`.

Use `-i` to see response headers. On Windows PowerShell, use `curl.exe` instead of `curl`, because `curl` is an alias for a different command.

```
curl -i https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/users/1
curl -i https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/reports/fast
curl -i https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/reports/slow
```

Expected:

- `/api/users/1` returns the user JSON and an `X-Correlation-Id` header.
- `/api/reports/fast` returns 200.
- `/api/reports/slow` returns 504 after about 3 seconds, because the service takes 5.

### Example output

Requests sent through GateX to the downstream mock services. Every response carries its own `X-Correlation-Id`, and the slow route is cut off by the gateway with a 504 instead of waiting for the downstream service.

![GET /api/users/1, GET /api/reports/fast and GET /api/reports/slow through GateX](docs/img_1.png)

### Create a user (POST)

On PowerShell, `Invoke-RestMethod` avoids JSON quoting problems:

```
Invoke-RestMethod -Method Post -Uri https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/users -ContentType "application/json" -Body '{"name":"Ana","role":"Analyst"}'
```

On macOS or Linux:

```
curl -i -X POST https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/users -H "Content-Type: application/json" -d '{"name":"Ana","role":"Analyst"}'
```

![POST /api/users through GateX returning User created successfully](docs/img.png)

### Trace propagation

Send your own ID and look for it in the response and in the UserService logs:

```
curl -i -H "X-Correlation-Id: demo-123" https://gatex-cqfhd5bvc2arade6.japaneast-01.azurewebsites.net/api/users/1
```

## Deploy to Azure App Service

GateX runs on Azure App Service (Linux, Java 21 Java SE) and is deployed from GitHub with GitHub Actions.

1. **Set the port.** In `application.yaml`, let App Service assign it:

   ```
   server:
     port: ${PORT:8082}
   ```

   Also lower the `TRACE` and `DEBUG` log levels to `INFO` for deployment, or the Azure log stream will be flooded.

2. **Create the Web App** in the Azure portal:
   - Publish: **Code**
   - Runtime stack: **Java 21**, Java web server stack: **Java SE**
   - Operating system: **Linux**
   - Region: one your subscription allows. Azure for Students restricts the list of regions, and this deployment uses **Japan East**.

3. **Connect GitHub.** Open the Web App, then **Deployment Center**:
   - Source: **GitHub** (click Authorize and sign in)
   - Organization, repository and branch: your account, `GateX`, `master`
   - Workflow option: **Add a workflow**
   - Click **Save**. Azure commits a workflow file (`master_GateX.yml`) to the repo and starts a build.

4. **Watch the build** on the repo's **Actions** tab. When the run is green, the app is live.

5. **Check it:**

   ```
   curl -i https://<your-app>.azurewebsites.net/api/users/1
   ```

   To see logs, open the Web App and use **Log stream** under Monitoring.

To redeploy, push to `master`. The workflow builds the jar with Maven and deploys it automatically.

## Notes

- `pom.xml` must be at the top level of the repository, not inside a nested folder, or the Azure workflow cannot find the project.
- Azure adds the workflow commit to your repo, so run `git pull` before your next push.
- The Azure Free plan sleeps when idle and has a small daily CPU quota, so the first request after a pause can be slow. Wake the gateway before running the timeout test.
- The downstream mock services may also sleep when idle. Wake them (call `/api/reports/fast` and `/api/users/1`) before running the timeout test. A cold start can take 10 to 30 seconds and will look like a gateway failure.
- Do not add the `PreserveHostHeader` filter. The downstream hosts route by Host header, so forwarding the gateway's host gives a 404.
- Keep secrets such as API keys in App Service **Environment variables** (or GitHub Actions secrets), not in the repo.
