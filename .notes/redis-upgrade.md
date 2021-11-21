Enable maintenance mode and scale down dynos:

```
heroku maintenance:on
heroku ps:scale web=0 worker=0
```

Fork Redis:

```
heroku config:get REDIS_URL
heroku addons:create heroku-redis:premium-5 --fork {{PREV_REDIS_URL}
```

Wait until ready:

```
heroku addons:info HEROKU_REDIS_ONYX
heroku redis:info
```

Promote Redis:

```
heroku redis:promote HEROKU_REDIS_ONYX
```

Update key eviction policy:

```
heroku redis:maxmemory HEROKU_REDIS_ONYX --policy volatile-lru
```

Confirm database is correct:

```
heroku redis:info
```

Disable preboot, scale up dynos and disable maintenance mode:

```
heroku features:disable preboot
heroku ps:scale web=2 worker=2
heroku maintenance:off
heroku features:enable preboot
```

Deprovisioning the prev Redis:

```
heroku addons:destroy {{PREV_REDIS_NAME}}
```
