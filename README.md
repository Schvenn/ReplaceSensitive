# ReplaceSensitive
This module replaces various strings within a user defined text file, including:

	• IPv4/IPv6 with RFC documentation ranges
	• Usernames over 3 characters in length, while preserving length and style
	• Domains when used with usernames (email or domain\user)
	• Redacts passwords with ≥1 letter, avoiding strings that represent ports like "/P: 123456"
	• Preserves whitespace and quoting exactly
	• Maintains 1:1 mappings for repeat appearances

It is designed to anonymize IPs, usernames, domains, and redact passwords so that files can be used with online services, such as LLMs, or create sample files for testing, while maintaining privacy of the original content.
