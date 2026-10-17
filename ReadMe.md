# GateX 

**A high-performance, lightweight API Gateway built with Java 21 Virtual Threads and Spring Cloud Gateway.**

GateX serves as a centralized edge service for a microservices architecture. It demonstrates modern cloud-native patterns by intercepting incoming traffic, applying declarative middleware filters, handling network resiliency, and routing requests to downstream services without the overhead of heavy, imperative code.

---

##  Architecture Overview

GateX acts as the single entry point to the system, decoupling clients from the backend infrastructure. 

```text
[ Client / Postman ] ---> [ GateX (Port 8080) ]
                                |
                                |---> [ User Service (8081) ]
                                |
                                |---> [ External Weather API ]
                                |
                                |---> [ Slow Report Service (8083) ]
```

## Key Features

*   **Dynamic Request Routing:** Routes traffic based on URI paths and HTTP methods, including dynamic path-rewriting (prefix stripping).
*   **Trace ID Injection (Observability):** Dynamically generates a UUID using Spring Expression Language (SpEL) and injects it as an `X-Correlation-Id` header into both upstream requests and downstream responses for distributed tracing.
*   **Gateway Resiliency:** Protects backend services from cascading failures by implementing strict response and connection timeouts (e.g., returning `504 Gateway Timeout` if a service takes longer than 3 seconds).
*   **High Concurrency with Virtual Threads:** Leverages Java 21's Virtual Threads (Project Loom) to handle thousands of concurrent blocking I/O calls without thread pool exhaustion.
*   **Zero-Boilerplate Configuration:** Entirely driven by declarative YAML configurations rather than custom Java middleware classes.

## Tech Stack

*   **Runtime:** Java 21 (JDK 21)
*   **Framework:** Spring Boot 3.3.4, Spring Cloud Gateway (2023.0.3)
*   **Concurrency Model:** Java Virtual Threads (`spring.threads.virtual.enabled=true`)
*   **Build Tool:** Maven (via Maven Wrapper)

---

## Getting Started

### Prerequisites
*   Java 21 installed (`JAVA_HOME` configured).
*   No local Maven installation required (uses embedded `mvnw`).

### Running GateX
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/gatex.git
   cd gatex
   ```
2. Start the gateway using the Maven wrapper:
   ```bash
   ./mvnw spring-boot:run
   ```
   *The gateway will start on `http://localhost:8080`.*

---

## Testing the Gateway

Once GateX and the mock microservices (User Service on `8081`, Report Service on `8083`) are running, use the following `curl` commands to test the routing and middleware.

### 1. Test Routing & Prefix Stripping
GateX intercepts the request, strips the `/api` prefix, injects the `X-Correlation-Id`, and forwards it to the User Service.

**Request:**
```bash
curl -i http://localhost:8080/api/users/123
```
**Expected Response:**
Notice the injected `X-Correlation-Id` in the response headers.
```text
HTTP/1.1 200 OK
X-Correlation-Id: 5c8f6b8a-1234-4b56-a789-abcdef123456
Content-Type: application/json

{
  "id": "123",
  "name": "Thiyane Xavier",
  "role": "Data Engineer",
  "status": "Active"
}
```

### 2. Test External Proxying & Query Parameters
GateX securely forwards requests and query parameters to external public APIs.

**Request:**
```bash
curl -i "http://localhost:8080/api/weather?city=London"
```

### 3. Test Resiliency (Timeout Handling)
The `/api/reports/slow` endpoint on the mock Report Service is intentionally designed to sleep for 5 seconds. GateX is configured to cut the connection after 3 seconds to protect system resources.

**Request:**
```bash
curl -i http://localhost:8080/api/reports/slow
```
**Expected Response:**
```text
HTTP/1.1 504 Gateway Timeout
X-Correlation-Id: d81a712f-9876-4d21-b345-ffccee998877
```

---

## Author
**Thiyane Xavier**
*   [LinkedIn](https://linkedin.com/in/thiyane-xavier/)
*   [GitHub](https://github.com/Thiyane24)