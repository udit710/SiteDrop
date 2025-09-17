# Contributing to Static Site Auto-Deployer

Thanks for your interest in improving this project! Here are some ways you can contribute:

## Types of Contributions

### 🐛 Bug Reports
- Use the GitHub issue template
- Include deployment logs from GitHub Actions
- Specify your AWS region and instance type
- Describe expected vs actual behavior

### 💡 Feature Requests
- Suggest improvements to the deployment process
- Request support for additional static site generators
- Propose new configuration options

### 🔧 Code Contributions
- Fix bugs in the GitHub Actions workflow
- Improve error handling and logging
- Add support for additional AWS services
- Enhance security configurations

## Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Test your changes with a real deployment
4. Update documentation if needed
5. Submit a pull request

## Testing Changes

Since this project deploys real AWS infrastructure:

1. Test in your own AWS account first
2. Use the smallest instance type possible (t2.nano if available)
3. Clean up resources after testing
4. Include deployment logs in your PR

## Code Style

- Use clear, descriptive variable names
- Add comments for complex bash scripts
- Follow YAML best practices for GitHub Actions
- Keep the deployment process simple and reliable

## Documentation

When adding features:
- Update README.md with new configuration options
- Add examples to SETUP.md if needed
- Update the troubleshooting section for new error cases

## Pull Request Process

1. Ensure your code works with a real deployment
2. Update documentation
3. Add a clear description of changes
4. Reference any related issues
5. Be responsive to feedback during review

## Questions?

Open an issue for questions about:
- How the deployment process works
- AWS configuration requirements
- Troubleshooting deployment issues