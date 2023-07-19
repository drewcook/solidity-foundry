# Encoding an SVG into a String

Use the `base64` command that comes shipped by default for some OS: `base64 -i {path/to/file.svg}`

This will output a base64 encoded string of the SVG.

To use it as a tokenURI within an NFT collection and to store it onchain, we can create a URI of it with the following additions:

- Adding `data:` protocol
- Adding `image/svg+xml` filetype
- Add `base64` encoding method

The format should be the following: `data:image/svg+xml;base64,{output string from previous command}`

```txt
data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB3aWR0aD0iNTAwIiBoZWlnaHQ9IjUwMCI+Cjx0ZXh0IHg9IjAiIHk9IjE1IiBmaWxsPSJibGFjayI+SGkhIFlvdXIgYnJvd3NlciBkZWNvZGVkIHRoaXM8L3RleHQ+Cjwvc3ZnPg==
```

Put the above URI into a browser to see the decoded image!
