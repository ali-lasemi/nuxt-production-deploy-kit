# Blue-Green Deployment Strategy

Blue-green deployment is a release strategy that keeps two production-like environments available.

One environment serves production traffic while the other receives the new release.

---

## Environments

- Blue
- Green

Example ports:

- Blue: 3001
- Green: 3002

---

## Deployment Flow

Deploy new version to inactive environment  
Run healthcheck  
Switch reverse proxy traffic  
Keep previous environment available  
Rollback quickly if needed

---

## Benefits

- Reduced downtime
- Safer production releases
- Faster rollback
- Better release confidence

---

## Example Nginx Strategy

The repository includes:

examples/blue-green/nginx-blue-green.conf

Traffic can be switched by changing the upstream target from blue to green or from green to blue.

---

## Production Notes

- Always validate inactive environment before switching traffic
- Keep both environments isolated
- Monitor logs during traffic switch
- Keep rollback path ready
- Automate healthchecks before switching