* the lambda src and layers directory structure. Install python libraries
* python modules would be installed via: cd lambda_functions && pip install -r requirements.txt --target layers/
```bash
lambda_functions/
├── requirements.txt
├── my_lambda_function.zip
├── my_lambda_layer.zip
├── layers
│   └── python
│       └── some_sdk
└── src
    └── aws-api-gateway.py
```
