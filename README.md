# s3-decompression-lambda

A simple Lambda function to decompress objects added to an S3 bucket and write
the resulting object to another bucket.

# Dependencies

Dependencies can be installed using bundler and npm using the following
commands:

```bash
bundle install --standalone --path vendor/bundle
npm install
```

# Building

An artifact for deployment can be built (and/or deployed) using the
[serverless][1] framework:

```bash
npx serverless package
```

You can use your own serverless configuration file and specify it as a command
line argument. For example:

```bash
npx serverless package --config my-serverless.yml
```

[1]: https://www.serverless.com/
