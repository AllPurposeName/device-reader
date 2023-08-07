# Device Readings Interview Project

## Summary
Imagine there are devices out in the field that record a count at arbitrary intervals.
These devices send readings over the internet to a centralized server for processing
and storage.

We would like you to implement a web API that receives and processes device
readings.

## Requirements
The web API needs to support the following functionalities:
* Store readings for devices
* Return the timestamp of the latest reading for a device
* Return the cumulative count across all readings for a device
* Due to the nature of the server, no data can be persisted to disk and must be stored in-memory

Feel free to implement the web API using any programming language, framework,
or third-party libraries.

Please limit yourself to 2 hours when working on this. If you run out of time,
add some notes in your README.md to describe what you would have worked on
given more time.

### Storing Readings
Devices send readings via HTTP POST requests with the following JSON:
```json
{
  "id": "36d5658a-6908-479e-887e-a949ec199272",
  "readings": [
    {
      "timestamp": "2021-09-29T16:08:15+01:00",
      "count": 2
    },
    {
      "timestamp": "2021-09-29T16:09:15+01:00",
      "count": 15
    }
  ]
}
```
Required Parameters
* id - a string representing the UUID for the device
* readings - an array of readings for the device
* timestamp - an ISO-8061 timestamp for when the reading was taken
* count - an integer representing the reading data

Readings can be sent out of order. There may also be duplicate readings for a given
timestamp. Any duplicate readings should be ignored.
Fetching the Latest Reading’s Timestamp
Clients can fetch the timestamp of the latest reading for a specific device via HTTP
GET requests. The API returns the following JSON:
```json
{
  "latest_timestamp": "2021-09-29T16:08:15+01:00"
}
```

#### Fetching the Cumulative Count
Clients can fetch the cumulative count of all readings for a specific device via HTTP
GET requests. The API returns the following JSON:
```json
{
"cumulative_count": 23
}
```

### Evaluation
Please include a README.md file with the following included:
* Instructions on how to build and start the web API locally
* Documentation for the API endpoints and any parameters required
* A brief summary of how the project is structured
* A list of improvements, items, optimizations you would have included if given
more time

We will evaluate your submission for the following criteria:
#### Functionality
 Does the API function according to the requirements? Are we able to get the server
up and running?
#### Design
Are components organized in a way that the code is easily readable? Are the most
efficient data structures used? Is the API designed using industry best practices?
#### Stability
Are we able to make sure the API continues to function as the underlying code
changes? How does the server handle unexpected JSON payloads?
#### Communication
How well does the code and accompanying documentation communicate ideas?
