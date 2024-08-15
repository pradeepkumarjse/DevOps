## Crate IAM Role with below details Source Account

### Add Below policy in Trust Realtionships

``` Javascript
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::target_account_id:user/pradeep"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
### Add below policy as cross_account_s3

``` Javascript
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::another-lambda"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::another-lambda/*"
        }
    ]
}
```
### Add below policy to user in target account as assume_role_cross_Account

``` Javascript
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::source_account_id:role/cross_account_s3_access"
    }
}
```
