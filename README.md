<div align="center">

# 💎 Intelligent Gem Cutting Robotic Arm
**BSc (Hons) in Information Technology – Final Year Research Project** *Sri Lanka Institute of Information Technology (SLIIT)* 

*Autonomous Intelligent Machines and Systems – RP-25J-231*

---

[![Robotics](https://img.shields.io/badge/Robotics-blue?style=for-the-badge)](https://www.sliit.lk/)
[![Embedded Systems](https://img.shields.io/badge/Embedded%20Systems-orange?style=for-the-badge)](https://www.sliit.lk/)
[![Machine Learning](https://img.shields.io/badge/Machine%20Learning-green?style=for-the-badge)](https://www.sliit.lk/)
[![3D Modelling](https://img.shields.io/badge/3D%20Modelling-blue?style=for-the-badge)](https://www.sliit.lk/)

</div>

---

##  Project Overview
This project aims to develop an intelligent robotic arm that automates the gemstone cutting process through robotics and artificial intelligence. Traditional gem cutting in Sri Lanka is labor-intensive, requires high skill, and often results in inconsistency.

The proposed system introduces a **semi-autonomous robotic solution** capable of identifying, evaluating, and cutting gemstones with precision and minimal human intervention. 

The research integrates **machine learning, robotics, embedded systems, and 3D Modelling** to create a prototype that can intelligently analyze gem characteristics and execute optimized cutting operations.

---

##  Architectural Diagram

<div align="center">
  <img src="https://raw.githubusercontent.com/Nihara-D/intelligent-gem-cutting-robot-arm-research/main/System%20Architecture.png" alt="System Architecture" width="900">
  <br>
  <em>Figure 1: High-level System Architecture showing the integration of ML Modules and Robotic Control</em>
</div>

---

##  System Workflow
The system performs four key functions:

<p align="center">
<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&color=00FF41&center=true&vCenter=true&width=435&lines=INITIALIZING+ROBOTIC+ARM...;SCANNING+GEMSTONE+GEOMETRY...;CALCULATING+OPTIMAL+CUT+PATH...;EXECUTING+PRECISION+FACETING...;SYSTEM+STATUS:+OPTIMAL" alt="Typing SVG" />
</p>

### 1. Robotic Arm Design, Control & Execution
#### **Overview**
This component focuses on controlling the robotic arm for gemstone cutting. The system combines hardware assembly, ROS 2 simulation, and web-based configuration to enable precise and programmable arm movements. The system allows simulation and real-time control of the arm, translating commands from the web app into servo motor actions.


> [!NOTE]
> The hardware used in this project is designed for academic purposes. It is a prototype setup and not intended for production-level deployment. The focus is on experimentation, learning, and demonstrating robotic arm control principles.

#### **1.1 Hardware Components**
| Category | Item | Specification |
| :--- | :--- | :--- |
| **Actuators** | 6× MG996R Servo Motors | High torque for precision |
| **Controllers** | ESP 32 S3 board | Primary Logic |
| **Computing** | Raspberry Pi 4 (4GB) | ROS 2 Environment |
| **Power** | 5V 20A & 5V 3A | Dual Supply System |
| **Interface** | PCA 9685 | Servo Controller Board |
| **Structure** | 6-DOF Robot Arm Kit | DIY Robotic Frame |
| **Misc** | Breadboard / Cables | Type-C / Micro USB / Jumper |

#### **1.2 Software & Simulation**
* **Operating System:** Ubuntu 24.04  
* **Framework:** ROS 2 Jazzy with Gazebo Harmonic for simulation  
* **Interface:** Web app configuration to bridge hardware and simulation via ROS 2 bridge  
* **Path Generation:** Creates precision cutting plans and movement trajectories based on stone analysis.

#### **1.3 Execution & Planning Strategy**
* **Movement Control:** Translates complex faceting coordinates into real-time servo pulses for high-precision cutting.
* **Path Planning:** Generates optimized cutting plans to navigate the arm along calculated trajectories, ensuring minimal material waste.
  
#### **1.4 Function**
The robotic arm performs precise physical movements for cutting operations. The system allows simulation and real-time control of the arm, translating commands from the web app into servo motor actions.

#### **1.5 Future Works**
* Adaptive Cutting with AI Feedback: Equip sensors (force, vibration, optical) to adjust cutting paths in real-time. Implement reinforcement learning for optimal strategies.
* Multi-Arm Systems: Expand to multi-arm setups for faster manufacturing and collaborative jewelry production.
* Cloud Operation: Develop a web dashboard for remote control, analytics, performance logs, and predictive maintenance.

---

### 2. Gem Identification
#### **2.1 Overview**
This component implements a machine learning–based gemstone identification and authenticity classification system tailored for Sri Lankan gemstones. This component implements a data-driven gemstone identification and authenticity assessment system designed with a focus on Sri Lankan gemstones. It serves as a decision-support and pre-screening module, assisting users in distinguishing natural, synthetic, imitation, and treated stones using measurable gemological properties.

The system combines visual information and key physical parameters to reduce reliance on subjective manual inspection and improve consistency in preliminary gem evaluation.

> [!NOTE]
> This is developed for academic purposes to demonstrate data-driven modeling. Evaluation focuses on methodology, not industrial-grade certification accuracy.

#### **2.2 Dataset Description**
The model is trained using a synthetically generated dataset containing 3,000+ records, constructed according to standard gemological reference ranges. The dataset represents realistic variations observed in Sri Lankan gem materials.:
* **Images,Refractive Index (RI), Specific Gravity (SG), Hardness (Mohs scale)**
* *Includes 34 Sri Lankan gemstone types (natural, Synthetic and treated stones, imitation and non-gem but valuable).*

#### **2.3 Model & Tools**
* **Approach:** Two-stage classification (Type identification + Authenticity classification).
* **Model:** Random Forest classifiers.
* **Tools:** `pandas`, `numpy`, `scikit-learn`, `matplotlib`, `joblib`.
* **Environment:** Google Colab.

#### **2.4 Future Works**
* Incorporate real laboratory gemological data.
* Add hierarchical classification and additional physical/optical features.
* Combine tabular data with image-based or spectral features.

---

### 3. Gem Evaluation

#### **3.1 Overview**

The function operates as an extension of the gem identification module, where the identified gem type, gem color, and captured gemstone images are provided as input data. The system analyzes the gem’s features and determines the optimal cutting method using AI-based or rule-driven logic to maximize gem value and minimize material loss.

> [!NOTE]
> This component is developed for academic and research purposes to demonstrate data-driven modeling. Evaluation focuses on conceptual methodology and implementation rather than industrial-grade certification.

#### **3.2 Image Preprocessing & Defect Detection**

Captured images are preprocessed to improve quality. Techniques such as noise removal, contrast enhancement, and segmentation are applied.

* **Process Flow:**
* Image quality is enhanced.
* Defective regions are identified using a supervised multi-class defect detection model.
* A visual defect map is generated and visualized.


* **Technical Detail:** The model is trained to identify five different types of gemstone defects using approximately **10 labeled images per defect category**.
* **Tools & Technologies:** `OpenCV`, `NumPy`, `TensorFlow / PyTorch`, `Python`.

#### **3.3 Weight Measurement**

The physical weight of the gemstone is measured using hardware sensors to ensure precise value estimation.

* **Mechanism:** Load cell sensor connected to an **HX711 module**.
* **Process Flow:**
* Gem is placed on the load cell.
* Sensor readings are captured and processed.
* Weight is digitally recorded for the integrated feature set.


* **Hardware:** Load Cell, HX711.

#### **3.4 Gem Value Estimation**

The system estimates the gemstone value by combining detected defects, measured weight, gem type, and reference market price data.

| Input Feature | Source |
| --- | --- |
| **Defect Map** | Multi-class Detection Model (PyTorch) |
| **Physical Weight** | Load Cell + HX711 Module |
| **Gem Type/Color** | Identification Module |
| **Market Reference** | Pricing Data Model |

**Final Output:** The system provides a fully automated and data-driven solution including a **visual defect map**, **accurate gemstone weight**, and an **estimated gemstone value**.

---

<p align="center">
  <img src="https://capsule-render.vercel.app/render?type=venom&color=00FF41&height=65&section=header&text=ANALYZING%20CUT%20GEOMETRY...&fontSize=20&animation=twinkling" />
</p>

### 4. Cut Type Recommendation

#### 4.1 Overview
This component recommends the most suitable gemstone cut type and predicts cutter-ready geometric parameters based on gemstone material properties and physical dimensions. The objective is to ensure cut feasibility while minimizing material wastage.

> [!NOTE]
> This component is developed for academic purposes to demonstrate data-driven cut planning. The emphasis is on methodological design rather than industrial-grade cutting optimization.



#### 4.2 Input Feature Processing
The module processes structured data from previous stages to analyze shape suitability and differentiate cut families.

| Source Module | Data Points Extracted |
| :--- | :--- |
| **Gem Identification** | Gem Type, Refractive Index (RI) |
| **Gem Evaluation** | Carat Weight, Length (mm), Width (mm), Height (mm) |
| **Derived Analytics** | **Aspect Ratio** (L/W) & **Depth Ratio** (H/W) |

---

#### 4.3 Cut Recommendation Models
The process is executed in two specialized stages to ensure logical consistency and maximum aesthetic yield.

**🔹 Stage 1: Exact Cut Family Classification**
Determines the broad category (Brilliant, Step, Mixed, or Cabochon) based on properties and derived ratios.
* **Model:** `CatBoost Classifier`
* **Purpose:** Handles categorical gem types and non-linear relationships.

**🔹 Stage 2: Cut Type Prediction**
Selects the precise cut within the identified family (e.g., Round, Oval, Pear, or Marquise).
* **Model:** `XGBoost Classifier`
* **Purpose:** Improves exact prediction accuracy and ensures geometric consistency.

---

#### Cut Parameter Prediction
Once the cut type is finalized, the system predicts specific geometric parameters to guide the **Robotic Arm Control** module:

* **Crown & Pavilion:** Optimized angles for light refraction.
* **Table & Depth:** Percentages calculated to minimize material loss.
* **Architecture:** Separate regression models are trained for each cut family to improve precision.

**Final Output:**
The system provides a data-driven recommendation including **Cut Family**, **Exact Cut Selection**, and **Geometric Cut Parameters** for automated execution.

---

<div align="center">

### Technical Stack
<img src="https://skillicons.dev/icons?i=ros,raspberrypi,linux,python,cpp,ubuntu,pytorch,tensorflow,opencv" />

<sub>© 2024-2026 | SLIIT AIMS Research Group</sub>

</div>











































