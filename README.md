# StockViz

StockViz is a comprehensive stock market visualization tool designed to process and analyze stock data efficiently. This project integrates AWS services to fetch, process, and display stock market data in real-time, providing insightful visualizations through Amazon QuickSight. The entire infrastructure is built using Infrastructure as Code (IaC) with Terraform, ensuring scalability, maintainability, and reproducibility.

---

## Features

- **Real-Time Stock Data Processing:** Uses AWS Lambda to fetch and process stock data via APIs.[APPLE,GOOGLE,MICROSOFT]
- **Data Visualization:** Displays stock data insights through Amazon QuickSight with various visualization options, including line charts, bar charts, and more.
- **Scalable Infrastructure:** Leverages AWS services like S3, SQS, and Lambda for a serverless and scalable architecture.
- **Error Handling:** Includes dead-letter queues for failed messages to ensure reliability.
- **Infrastructure as Code:** The entire system is provisioned and managed using Terraform, enabling consistent and repeatable deployments.

---

## Architecture Overview



1. **Data Fetching:**
   - AWS Lambda function (`lambda-api-reader`) retrieves stock data from an external API.
   - Data is processed and stored in S3 for further analysis.

2. **Message Queueing:**
   - AWS SQS is used to queue data processing tasks.
   - A dead-letter queue ensures failed messages are logged for troubleshooting.

3. **Data Visualization:**
   - Data is imported into Amazon QuickSight for interactive visualization.
   - Visualizations include line charts, stacked bar charts, and more, with fields such as `price`, `ticker`, `timestamp`, and `currency`.

4. **Infrastructure as Code:**
   - Terraform is used to define and provision AWS resources, ensuring the environment is consistent and easily replicable.

---

## Setup and Deployment

1. Clone this repository:
   ```bash
   git clone https://github.com/genin6382/StockViz.git
   cd StockViz
   ```

2. Install Terraform and initialize the configuration:
   ```bash
   terraform init
   ```

3. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

4. Configure Amazon QuickSight:
   - Add the dataset generated in S3 to QuickSight.
   - Create desired visualizations using the imported fields.

5. Create and Deploy Lambda Layer:
   - Create a new directory structure for the layer:
     ```bash
     mkdir -p lambda-layer/python
     cd lambda-layer
     ```
   - Create a `requirements.txt` file:
     ```bash
     echo "requests==2.31.0" > requirements.txt
     echo "urllib3<1.27" >> requirements.txt
     ```
   - Install dependencies to the `python` directory:
     ```bash
     pip install --platform manylinux2014_x86_64 --implementation cp --python-version 3.9 --only-binary=:all: --upgrade -r requirements.txt -t python/
     ```
   - Create the layer ZIP file:
     ```bash
     zip -r lambda-layer.zip python/
     ```
   - Upload the ZIP file to AWS Lambda as a new layer.

---

## Prerequisites

- AWS account with appropriate permissions.
- Terraform installed on your local machine.
- Amazon QuickSight subscription.

---

## Usage

1. Trigger the data-fetching Lambda function to start processing stock data.
2. View processed data in Amazon QuickSight.
3. Customize visualizations as needed.

---

## Technologies Used

- **AWS Services:** S3, Lambda, SQS, QuickSight, IAM
- **Programming Language:** Python (for Lambda functions)
- **Infrastructure as Code:** Terraform

---

## License

This project is licensed under the [MIT License](LICENSE).

---



