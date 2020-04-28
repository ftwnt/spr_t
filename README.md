## Niche [rozetka.com.ua]() scrapper

### Dependencies

* [redis](https://redis.io/)

### Description

#### `Scrapper#perform` 
1. Fetches `rozetka` page.
2. Retrieves encoded script for dynamically retrieved data.
3. Decodes needed endpoints to fetch data and calls it. 
4. Retrieves URL, title, price, reviews amount and stock availability for all the items from list.
If no results -- the `'Nothing has been found'` message is used.
5. The data is serialized and placed to `redis`.
6. `redis` keeps data until `Scrapper#retrieve_and_uncache_results` is successfully executed.

#### `Scrapper#retrieve_and_uncache_results`
1. Retrieves data from `redis` by a key with pattern `rozetka::GIVEN_URL`, where `GIVEN_URL` is
url defined for scrapping in the object.
2. Deserializes, sorts results by reviews amount and price in descending order and outputs 
the retrieved data in ***URL Price Comments Name*** format row by row.
3. Returns nothing if `redis` key not found.
4. Removes the key from the store after successful output.

### Execution

Run the bin script with desired url for scrapping, e.g.:

`bin/run "https://rozetka.com.ua/mobile-phones/c80003/preset\=smartfon/"` 


### Links for testing

| Type | Link |
| --- | --- |
| No goods | https://rozetka.com.ua/mobile-phones/c80003/preset=smartfon;producer=sony;49180=103100/ |
| Goods on 1 page | https://rozetka.com.ua/mobile-phones/c80003/preset=smartfon;producer=apple/ |
| Goods on multiple pages | https://rozetka.com.ua/mobile-phones/c80003/preset=smartfon/ |
