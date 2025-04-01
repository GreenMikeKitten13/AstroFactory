using UnityEngine;
using UnityEngine.InputSystem;
using System.Collections;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

public class PlayerScript : MonoBehaviour
{
    readonly float speed = 5.0f;
    readonly float rotationSpeed = 2.5f;
    bool cooldown = false;

    private Vector2 movement;
    GameObject bulletPrefab;

    private void Start()
    {
        Addressables.LoadAssetAsync<GameObject>("BulletPrefab").Completed += handle =>
        {
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                bulletPrefab = handle.Result;
            }
            else
            {
                Debug.LogError("Failed to load BulletPrefab from Addressables!");
            }
        };
    }

    void Update()
    {
        float vertical = Input.GetAxisRaw("Vertical");
        float horizontal = Input.GetAxisRaw("Horizontal");
        float fire = Input.GetAxisRaw("Fire1");

        movement = transform.up * vertical + transform.right * horizontal;

        if (movement.magnitude > 1f) movement.Normalize();
        if (movement.sqrMagnitude > 0.01f) RotateTowardsMovement(movement);
        if (Mouse.current.leftButton.isPressed) RotateTowardsMouse();

        if (fire != 0 && !cooldown && bulletPrefab != null)
        {
            Shoot();
        }

    }

    void FixedUpdate()
    {
        transform.position += speed * Time.fixedDeltaTime * (Vector3)movement;
    }

    void RotateTowardsMovement(Vector2 direction)
    {
        float targetAngle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 90f;
        float newAngle = Mathf.LerpAngle(transform.eulerAngles.z, targetAngle, rotationSpeed * Time.deltaTime);
        transform.rotation = Quaternion.Euler(0, 0, newAngle);
    }

    void RotateTowardsMouse()
    {
        Vector3 mousePos = Camera.main.ScreenToWorldPoint(Mouse.current.position.ReadValue());
        mousePos.z = 0f;

        Vector2 direction = (mousePos - transform.position).normalized;
        float targetAngle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 90f;
        transform.rotation = Quaternion.Euler(0, 0, targetAngle);
    }

    GameObject bullet;
    void Shoot()
    {
        cooldown = true;
        StartCoroutine(ResetCooldown());

        Debug.Log("Fire");
        bullet = Instantiate(bulletPrefab, transform.position, transform.rotation);
        bullet.GetComponent<Rigidbody2D>().AddForce(transform.up * 20, ForceMode2D.Impulse);
        bullet.GetComponent<SpriteRenderer>().sortingOrder = 2;


    }

    IEnumerator ResetCooldown()
    {
        yield return new WaitForSeconds(0.8f);
        cooldown = false;
        if (bullet != null) Destroy(bullet);
    }
}
