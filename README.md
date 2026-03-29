# 🚀 DevOpsFactor Streaming App

![Node.js](https://img.shields.io/badge/Node.js-18-green)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-blueviolet)
![CI/CD](https://img.shields.io/badge/CI/CD-Jenkins-red)
![Security](https://img.shields.io/badge/Security-Trivy%20%7C%20OWASP-yellow)

---

## 🎬 Project Preview (GIF)

> 🔥 Add your app demo GIF here (record using screen recorder & upload to repo)

![App Demo](./public/images/demo.gif)

---

## 📌 About Project

A **Netflix-style streaming web application** built using **Node.js, Express, and EJS**, integrated with a **complete DevOps & DevSecOps pipeline**.

This project demonstrates **real-world production workflow**:

👉 Code → Build → Scan → Deploy → Secure 🚀

---

## 🏗️ Architecture Diagram

```text
                👨‍💻 Developer
                      │
                      ▼
                  GitHub Repo
                      │
                      ▼
               ⚙️ Jenkins Pipeline
                      │
        ┌─────────────┼─────────────┐
        ▼                             ▼
 🔍 SonarQube                  🔐 Trivy Scan
 (Code Quality)           (Container Security)
        │                             │
        └─────────────┬─────────────┘
                      ▼
               🐳 Docker Build
                      │
                      ▼
               📦 Docker Image
                      │
                      ▼
            ☸️ AWS EKS (Fargate)
                      │
                      ▼
                🌐 End Users
```

---

## 🛠️ Tech Stack

| Category         | Tools                      |
| ---------------- | -------------------------- |
| Backend          | Node.js, Express.js        |
| Frontend         | EJS, CSS                   |
| Containerization | Docker                     |
| Cloud            | AWS EC2, AWS EKS (Fargate) |
| CI/CD            | Jenkins                    |
| Code Quality     | SonarQube                  |
| Security         | Trivy, OWASP ZAP           |

---

## 📂 Project Structure

```bash
├── app.js
├── package.json
├── data/
│   └── movies.json
├── public/
│   ├── css/
│   └── images/
├── views/
│   ├── layout.ejs
│   ├── index.ejs
│   ├── movie.ejs
│   ├── login.ejs
│   └── signup.ejs
```

---

## 🚀 Run Locally

```bash
git clone https://github.com/rakesh-perala/nodejs-streaming-app-devopsfactor.git
cd nodejs-streaming-app-devopsfactor
npm install
node app.js
```

👉 Open:

```
http://localhost:3000
```

---

## 🐳 Docker Setup

### Build Image

```bash
docker build -t devopsfactor-app .
```

### Run Container

```bash
docker run -d -p 3000:3000 --name devops-app devopsfactor-app
```

---

## ☁️ AWS EC2 Deployment

* Launch EC2 instance
* Install Docker
* Clone repo
* Build & run container

👉 Access:

```
http://<EC2-PUBLIC-IP>:3000
```

---

## ☸️ Kubernetes Deployment (EKS Fargate)

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

## 🔐 DevSecOps Pipeline

✔ Jenkins – CI/CD automation
✔ SonarQube – Code quality analysis
✔ Trivy – Vulnerability scanning
✔ OWASP ZAP – Security testing

---

## 🎯 Features

* 🎬 Movie streaming UI
* 📄 Movie details page
* 📱 Responsive design
* 🧩 Clean architecture
* ☁️ Cloud-ready

---

## 🚀 Future Enhancements

* 🔐 JWT Authentication
* 📤 Upload videos
* ⚙️ GitHub Actions CI/CD
* 🌐 Custom domain + HTTPS
* 📊 Monitoring (CloudWatch / Prometheus)

---

## 👨‍💻 Author

**Rakesh (DevOpsFactor)** 🚀

---

## ⭐ Support

If you like this project:

⭐ Star the repo
📢 Share with others
🚀 Keep building DevOps projects
