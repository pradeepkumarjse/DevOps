### Crate IAM Role with below details

## Add Below policy in Trust Realtionships

``` Javascript
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::254438258404:user/pradeep"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```
