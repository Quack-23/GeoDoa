# DIAGRAMS FOR ADAPTIVE BACKGROUND SCANNING ARTICLE

## 1. ALGORITHM ARCHITECTURE DIAGRAM

```mermaid
graph TD
    A[User Input] --> B[Scan Mode Selection]
    B --> C{Mode Type}
    C -->|Realtime| D[5 min interval<br/>10m threshold]
    C -->|Balanced| E[15 min interval<br/>25m threshold]
    C -->|Powersave| F[30 min interval<br/>50m threshold]
    
    D --> G[Dynamic Threshold Calculation]
    E --> G
    F --> G
    
    G --> H[Battery Level Check]
    H --> I[Adaptive Threshold Adjustment]
    I --> J[Movement Detection]
    J --> K{Distance ≥ Threshold?}
    K -->|Yes| L[Perform Scan]
    K -->|No| M[Skip Scan]
    
    L --> N[Update Position History]
    M --> N
    N --> O[Adaptive Learning]
    O --> P[Performance Monitoring]
    
    style A fill:#e1f5fe
    style L fill:#c8e6c9
    style M fill:#ffcdd2
    style G fill:#fff3e0
```

## 2. PERFORMANCE COMPARISON CHART

```mermaid
graph LR
    subgraph "Battery Consumption (mAh/day)"
        A1[Fixed 5min<br/>480 mAh] 
        A2[Fixed 15min<br/>240 mAh]
        A3[Fixed 30min<br/>120 mAh]
        A4[Our Algorithm<br/>180 mAh]
    end
    
    subgraph "Scan Success Rate (%)"
        B1[Fixed 5min<br/>78%]
        B2[Fixed 15min<br/>85%]
        B3[Fixed 30min<br/>90%]
        B4[Our Algorithm<br/>94%]
    end
    
    subgraph "User Satisfaction (/10)"
        C1[Fixed 5min<br/>8.2/10]
        C2[Fixed 15min<br/>7.8/10]
        C3[Fixed 30min<br/>6.9/10]
        C4[Our Algorithm<br/>8.5/10]
    end
    
    style A4 fill:#4caf50,color:#fff
    style B4 fill:#4caf50,color:#fff
    style C4 fill:#4caf50,color:#fff
```

## 3. ADAPTIVE THRESHOLD CALCULATION FLOW

```mermaid
flowchart TD
    A[Current Battery Level] --> B{Battery Level Check}
    B -->|100%| C[battery_factor = 1.0]
    B -->|75%| D[battery_factor = 1.125]
    B -->|50%| E[battery_factor = 1.25]
    B -->|25%| F[battery_factor = 1.375]
    B -->|10%| G[battery_factor = 1.45]
    
    H[Selected Mode] --> I{Mode Type}
    I -->|Realtime| J[base_threshold = 10m<br/>multiplier = 1.0]
    I -->|Balanced| K[base_threshold = 25m<br/>multiplier = 2.5]
    I -->|Powersave| L[base_threshold = 50m<br/>multiplier = 5.0]
    
    C --> M[Calculate Adaptive Threshold]
    D --> M
    E --> M
    F --> M
    G --> M
    
    J --> M
    K --> M
    L --> M
    
    M --> N[adaptive_threshold = base_threshold × multiplier × battery_factor]
    N --> O[Apply Threshold to Movement Detection]
    
    style M fill:#ff9800,color:#fff
    style N fill:#4caf50,color:#fff
```

## 4. EXPERIMENTAL SETUP OVERVIEW

```mermaid
graph TB
    subgraph "Hardware Environment"
        A1[Samsung Galaxy S21]
        A2[OnePlus 9]
        A3[Xiaomi Mi 11]
        A4[iPhone 12]
        A5[iPhone 13]
        A6[iPhone 14]
    end
    
    subgraph "Software Environment"
        B1[Flutter 3.10+]
        B2[Android API 21+]
        B3[iOS 14.0+]
    end
    
    subgraph "Test Scenarios"
        C1[Urban Dense Areas]
        C2[Suburban Areas]
        C3[Rural Areas]
    end
    
    subgraph "Evaluation Metrics"
        D1[Battery Consumption]
        D2[Scanning Efficiency]
        D3[User Experience]
        D4[System Performance]
    end
    
    A1 --> E[30-Day Testing Period]
    A2 --> E
    A3 --> E
    A4 --> E
    A5 --> E
    A6 --> E
    
    B1 --> E
    B2 --> E
    B3 --> E
    
    C1 --> E
    C2 --> E
    C3 --> E
    
    E --> D1
    E --> D2
    E --> D3
    E --> D4
    
    style E fill:#2196f3,color:#fff
```

## 5. MATHEMATICAL MODEL VISUALIZATION

```mermaid
graph LR
    subgraph "Input Variables"
        A1[base_threshold = 10m]
        A2[mode_multiplier = {1.0, 2.5, 5.0}]
        A3[battery_level ∈ [0,1]]
    end
    
    subgraph "Calculations"
        B1[battery_factor = 1.0 + 0.5 × (1 - battery_level)]
        B2[threshold = base_threshold × mode_multiplier]
        B3[adaptive_threshold = threshold × battery_factor]
    end
    
    subgraph "Output"
        C1[Final Threshold Value]
        C2[Movement Detection Decision]
    end
    
    A1 --> B2
    A2 --> B2
    A3 --> B1
    
    B1 --> B3
    B2 --> B3
    
    B3 --> C1
    C1 --> C2
    
    style B3 fill:#9c27b0,color:#fff
    style C1 fill:#4caf50,color:#fff
```

## 6. USER EXPERIENCE IMPROVEMENT FLOW

```mermaid
journey
    title User Experience Journey with Adaptive Algorithm
    section Initial Setup
      User selects mode: 3: User
      Algorithm learns patterns: 4: Algorithm
      Initial adaptation period: 2: System
    section Daily Usage
      Automatic threshold adjustment: 5: Algorithm
      Battery-aware scanning: 5: Algorithm
      Reduced unnecessary scans: 4: System
    section Long-term Benefits
      Improved battery life: 5: User
      Better app responsiveness: 5: User
      Higher satisfaction: 5: User
      Reduced app abandonment: 4: Developer
```

---

## 📝 **CARA MENGGUNAKAN DIAGRAM INI:**

1. **Mermaid Diagrams** - Copy kode dan paste di editor yang support Mermaid (GitHub, GitLab, dll.)
2. **Untuk Artikel** - Bisa dikonversi ke gambar atau digunakan sebagai referensi visual
3. **Untuk Presentasi** - Bisa di-export sebagai gambar atau digunakan langsung

**Apakah Anda ingin saya buat diagram lain atau memodifikasi yang sudah ada?**
