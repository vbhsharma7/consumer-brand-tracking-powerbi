# Power BI setup and starter DAX

## Relationships
Create one-to-many relationships:
- DimRespondent[RespondentID] → FactSurveyResponse[RespondentID]
- DimBrand[BrandID] → FactSurveyResponse[BrandID]
- DimWave[WaveID] → FactSurveyResponse[WaveID]
- DimQuestion[QuestionID] → FactSurveyResponse[QuestionID]

Use single-direction filtering from dimensions to fact. Ensure each dimension key is unique.

## Starter measures
Use the table names exactly as shown below. If Power BI creates different table names, adjust the DAX.

```DAX
Awareness Yes =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Awareness",
    FactSurveyResponse[ResponseValue] = "Yes",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Awareness Eligible =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Awareness",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Awareness % =
DIVIDE([Awareness Yes], [Awareness Eligible])

Consideration Yes =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Consideration",
    FactSurveyResponse[ResponseValue] = "Yes",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Consideration Eligible =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Consideration",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Consideration % =
DIVIDE([Consideration Yes], [Consideration Eligible])

Purchase Yes =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Purchase",
    FactSurveyResponse[ResponseValue] = "Yes",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Purchase Eligible =
CALCULATE(
    DISTINCTCOUNT(FactSurveyResponse[RespondentID]),
    DimQuestion[MetricType] = "Purchase",
    FactSurveyResponse[ResponseStatus] = "Valid"
)

Purchase % =
DIVIDE([Purchase Yes], [Purchase Eligible])

Average Satisfaction =
CALCULATE(
    AVERAGE(FactSurveyResponse[NumericValue]),
    DimQuestion[MetricType] = "Satisfaction",
    FactSurveyResponse[ResponseStatus] = "Valid"
)
```

Format percentage measures as Percentage. Because the survey uses conditional routing, these measures calculate rates among valid responses to each question. This is not the same as the percentage of all respondents who purchased. State the denominator clearly in report titles.

## Dashboard pages
1. Executive overview: awareness %, consideration %, purchase %, average satisfaction.
2. Brand comparison: clustered bar chart by BrandName, with WaveName slicer.
3. Consumer segments: matrix or bar charts by AgeGroup and Region.
4. Data quality: raw rows, duplicate grain rows, invalid satisfaction count, and clean rows. You can import `qc_summary.txt` or create a separate QC summary CSV from Python.

## Interpretation prompts
- Which brand improved awareness most from Wave 1 to Wave 2?
- Does consideration differ by region or age group?
- Which brand has the highest satisfaction among purchasers who answered the question?
- How do data-quality exclusions affect reported metrics?
