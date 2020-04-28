## Niche [rozetka.com.ua]() scrapper

### Dependencies

* [redis](https://redis.io/)
* [chromedriver](https://github.com/SeleniumHQ/selenium/wiki/ChromeDriver)

### Description

#### `Scrapper#perform` 
1. Crawls through the first two pages for the provided url 
(even if there are more pages defined in the filter params), 
2. Retrieves URL, title, price, reviews amount and stock availability for all the items from list.
If no results -- the `'Nothing has been found'` message is used.
3. The data is serialized and placed to `redis`.
4. `redis` keeps data until `Scrapper#retrieve_and_uncache_results` is successfully executed.

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
