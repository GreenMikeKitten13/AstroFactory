using UnityEngine;
using UnityEngine.InputSystem;
using System.Collections;

public class PlayerScript : MonoBehaviour
{
    readonly float speed = 5.0f;
    readonly float rotationSpeed = 2.5f;
    bool cooldown = false;

    private Vector2 movement;

    public GameObject bulletPrefab;


    void Update()
    {
        float vertical = Input.GetAxisRaw("Vertical");
        float horizontal = Input.GetAxisRaw("Horizontal");
        float fire = Input.GetAxisRaw("Fire1"); // "Fire1" corresponds to Left Ctrl or F by default

        // Convert input into a movement vector relative to the character's facing direction
        movement = transform.up * vertical + transform.right * horizontal;

        // Normalize to prevent diagonal speed boost
        if (movement.magnitude > 1f) movement.Normalize();

        // Rotate towards movement direction if moving
        if (movement.sqrMagnitude > 0.01f)
        {
            RotateTowardsMovement(movement);
        }

        // Rotate towards mouse when left mouse button is held
        if (Mouse.current.leftButton.isPressed)
        {
            RotateTowardsMouse();
        }

        // Fire when pressing "Fire1" (F key) and no cooldown
        if (fire != 0 && !cooldown)
        {
            Shoot();
        }
    }

    void FixedUpdate()
    {
        // Move character in the direction it is facing
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

    void Shoot()
    {
        Debug.Log("Fire");
        GameObject bullet = Instantiate(bulletPrefab, transform.position, transform.rotation);
        bullet.GetComponent<Rigidbody2D>().AddForce(transform.up * 10, ForceMode2D.Impulse);
        bullet.GetComponent<SpriteRenderer>().sortingOrder = 2;

        // Start cooldown
        cooldown = true;
        StartCoroutine(ResetCooldown());
    }

    IEnumerator ResetCooldown()
    {
        yield return new WaitForSeconds(0.8f);
        cooldown = false;
    }
}
