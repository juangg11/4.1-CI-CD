# CI/CD con Flask y GitHub Actions

Práctica de introducción a **CI/CD** (Integración Continua y Entrega/Despliegue Continuo) para una aplicación web Flask.

---

## Tabla de contenidos

- [Descripción del proyecto](#descripción-del-proyecto)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Cómo ejecutar localmente](#cómo-ejecutar-localmente)
- [Tests unitarios](#tests-unitarios)
- [Pipeline CI/CD](#pipeline-cicd)
  - [CI – Integración Continua](#ci--integración-continua)
  - [CD – Entrega Continua a Docker Hub](#cd--entrega-continua-a-docker-hub)
  - [CD – Despliegue Continuo en AWS](#cd--despliegue-continuo-en-aws)
- [Secrets necesarios en GitHub](#secrets-necesarios-en-github)

---

## Descripción del proyecto

Esta práctica implementa un pipeline de CI/CD completo para una aplicación Flask mínima que devuelve `Hello, World!`. El objetivo es automatizar todo el ciclo de vida del software:

1. **CI**: Ejecutar tests automáticamente ante cada `push` a `main`.
2. **CD (Docker Hub)**: Construir y publicar la imagen Docker si los tests pasan.
3. **CD (AWS)**: Desplegar la imagen en **AWS App Runner** usando **Amazon ECR**.

---

## Estructura del proyecto

```
ci-cd-flask/
├── .github/
│   └── workflows/
│       ├── ci-cd-preproduction.yml        # CI + Docker Hub
│       └── ci-cd-preproduction-aws.yaml   # CI + ECR + AWS App Runner
├── src/
│   └── app.py           # Aplicación Flask
├── tests/
│   └── test.py          # Tests unitarios con unittest
├── Dockerfile           # Imagen Docker de la app
├── requirements.txt     # Dependencias Python
└── README.md
```

---

## Cómo ejecutar localmente

### 1. Crear y activar el entorno virtual

```bash
# Crear el entorno virtual
python -m venv venv

# Activar (Linux/Mac)
source venv/bin/activate

# Activar (Windows)
venv\Scripts\activate
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Ejecutar la aplicación

```bash
python src/app.py
```

La app estará disponible en `http://localhost:8000`

### 4. Desactivar el entorno virtual

```bash
deactivate
```

---

## Tests unitarios

Los tests usan [`unittest`](https://docs.python.org/3/library/unittest.html), el framework de testing integrado en Python.

Para ejecutarlos desde la raíz del proyecto:

```bash
python -m unittest tests/*.py
```

El test `test_home` verifica que la ruta `/` devuelve código `200` y el texto `Hello, World!`.

**Resultado esperado:**

```
test_home (tests.test.BasicTests.test_home) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.027s

OK
```

---

## Pipeline CI/CD

### CI – Integración Continua

**Archivo:** `.github/workflows/ci-cd-preproduction.yml`

Se activa automáticamente en cada `push` a la rama `main`. El job `test`:

1. Configura Python 3.13 en un runner Ubuntu
2. Instala las dependencias de `requirements.txt`
3. Ejecuta los tests con `python -m unittest tests/*.py`

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.13'
      - run: pip install -r requirements.txt
      - run: python -m unittest tests/*.py
```

---

### CD – Entrega Continua a Docker Hub

**Archivo:** `.github/workflows/ci-cd-preproduction.yml` (job `build-and-push`)

Solo se ejecuta **si los tests pasan** (`needs: test`). Hace:

1. Login en Docker Hub usando secrets del repositorio
2. Build de la imagen Docker: `docker build -t <usuario>/ci-cd-flask:latest .`
3. Push de la imagen a Docker Hub

```yaml
  build-and-push:
    needs: test
    steps:
      - run: echo "${{ secrets.DOCKER_HUB_TOKEN }}" | docker login -u "${{ secrets.DOCKER_HUB_USERNAME }}" --password-stdin
      - run: docker build -t ${{ secrets.DOCKER_HUB_USERNAME }}/ci-cd-flask:latest .
      - run: docker push ${{ secrets.DOCKER_HUB_USERNAME }}/ci-cd-flask:latest
```

---

### CD – Despliegue Continuo en AWS

**Archivo:** `.github/workflows/ci-cd-preproduction-aws.yaml`

Pipeline completo con 3 jobs secuenciales:

| Job | Descripción |
|-----|-------------|
| `test` | Ejecuta los tests unitarios |
| `build-and-push` | Construye la imagen y la sube a **Amazon ECR** con el tag del commit (`github.sha`) |
| `deploy` | Despliega la imagen en **AWS App Runner** |

El flujo completo:

```
push a main
    │
    ▼
[ test ] ──OK──> [ build-and-push -> ECR ] ──OK──> [ deploy -> App Runner ]
    │
    FAIL (si falla, se detiene aquí)
```

---

## Secrets necesarios en GitHub

Ve a **Settings → Secrets and variables → Actions** en tu repositorio y añade:

### Para el workflow de Docker Hub

| Secret | Descripción |
|--------|-------------|
| `DOCKER_HUB_USERNAME` | Tu nombre de usuario de Docker Hub |
| `DOCKER_HUB_TOKEN` | Token de acceso generado en Docker Hub |

### Para el workflow de AWS (opcional)

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key del usuario IAM de AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret Key del usuario IAM de AWS |
| `AWS_APP_RUNNER_ROLE_ARN` | ARN del rol de acceso de App Runner |

---

## Dockerfile

```dockerfile
FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src .

EXPOSE 8000

CMD ["python", "app.py"]
```

![alt text](image.png)
