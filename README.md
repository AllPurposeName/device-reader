# Conclusion
### Running Instructions
Rails version 7.0.6
Ruby version 3.2.2
After cloning the repo, run `bundle`
Once there, you can run `bundle exec rspec` for specs, `rails s` for the server,
and `rails c` for a console.

### API Documentation
There are two API endpoints, a device reading create and a device reading show.
### **GET** `/device_reading/:id`
#### Parameters

```json=
{
}
```

#### Response
##### 200
```json=
{
  "latest_timestamp": string - Datetime
  "cumulative_count": int
}
```
#### Note:
If an invalid id is supplied, timestamp and count will be zeroed.

### **POST** `/device_reading`

#### Parameters

```json=
{
  "id": string - uuid
  "reading":
    {
      "timestamp": string - Datetime
      "count": int
    }
  ]
}
```

#### Response
##### 201
```json=
{
}
```

##### 422
```json=
{
  "message": string - "Missing or invalid parameters: " one of [id, reading,
  timestamp, count]
}
```

### Structural Explanation

The project was structured as simply as I could managed given the constraints.
At the entry point, we have a simple and stupid controller which simply passes
along parameters to a service and renders their responses as json with a little
bit of error message presentation functionality.

One layer down we have the `DeviceReadingMemoryStorage` service which has 2 class
methods intended as it's public API: `.ingest!` and `.read`. Aside from both
relying on the data `device_reading`, these flows do not re-use any code, so
breaking the service in two is probably recommended. Currently it serves as the
"outroface" for our memory store, so an argument could be made to keep it intact
as the sole user of that dependency.

The service relies on the model `DeviceReading` which does two things: holds
data to be validated, and gives us useful methods for later interacting with the
memory store such as `#hashed`, `#cumulative_count` and `#timestamps`

I had some trouble getting validations to work out of the box as I wanted, so I
quickly (and sloppily) wrote a custom validator to get me what I wanted. The one
advantage I see in keeping this class around is if complexity pops up for the
device_reading inputs. I would recommend moving away from this. Either validate
the params further up the chain, or rely on more standard Rails validations.

Lastly we should touch on the memory store itself. We're using local memory, so
no changes are persisted if the server is shut down or if we require multiple
servers. This was done to save time, but for a more serious application I would
move this responsibility to Redis or Memcached. The cache keys I use are: hashed
device reading (md5 hexdigest), device_id/cumulative_count,
device_id/latest_timestamp, and device_id.

* The hashed reading is for a quick and inexpensive idempotency guard clause.
* The cumulative count and latest timestamp are the given requirements, so we're
going for a heavy write, light read here. The complications I anticipate are
using a lot of storage for these uncompressed values, as well as having trouble
handling high volume of writes.
* The device id is to store the readings themselves so we can later do
cumulative_count and latest_timestamp writes based off of historical data.

### Followups
1. As mentioned above, use a production ready memory storage.
2. Have a better response body: This is a REST API and so we're saying the
   resource "device_reading" has two parts, cumulative_count, and
   latest_timestamp. I would rather return all timestamps and counts with the
   abilities to sort and filter. `/device_readings/:id?-sort[timestamps]&page=1&per-page=1`
   is the API way of saying `latest_timestamp`. This for free gives us the
   `first_timestamp` feature without any more code. We cannot anticipate the
   use cases of our clients, so we ought to give them the tools they need for
   nearly anything upfront. The investment is admittedly more than 2 hours
   worth, but not much more. Cumulative count may still be necessary as a top
   level field.
3. I would flesh out a `Reading` class and move some of the validations there. A
   DeviceReading has responsibiltiies given multiple `count & timestamp` combos.
   It should be able to anticipate well formed combos.
4. More percise error handling so the response the clients receive instructs them
   on what exactly needs to change.
5. It would have been nice to stress test the system and see how it starts to
   fall apart once memory constraints become an issue. I only have experience
   with memory storage as a simple caching layer, so I stretched a bit using
   it in place of a database. It would have been nice to gleam more learnings
   about its limitations.
6. Timestamps are not unique per device, but a reading is (timestamp + count). I
   was unsure of the product requirement around duplicate entries, but
   considering the language `Any duplicate readings should be ignored.` I took a
   `reading` as the combo of the two. Thus, a device could affirmatively receive
   readings from the same timestamp as long as the counts vary.

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
