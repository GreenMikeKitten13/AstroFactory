using UnityEngine;

public class PlayerScript : MonoBehaviour
{
    readonly float speed = 7.0f;
    readonly float rotationSpeed = 3f; // Degrees per second

    private Vector2 movement;

    void Update()
    {
        float vertical = Input.GetAxisRaw("Vertical");   // W/S or Up/Down arrow
        float horizontal = Input.GetAxisRaw("Horizontal"); // A/D or Left/Right arrow

        // Convert input into a movement vector relative to the character's facing direction
        movement = transform.up * vertical + transform.right * horizontal;

        // Normalize to prevent diagonal speed boost
        if (movement.magnitude > 1f) movement.Normalize();

        // Rotate towards movement direction if moving
        if (movement.sqrMagnitude > 0.01f)
        {
            RotateTowardsMovement(movement);
        }
    }

    void FixedUpdate()
    {
        // Move character in the direction it is facing
        transform.position += speed*Time.fixedDeltaTime*(Vector3)movement;
    }

    void RotateTowardsMovement(Vector2 direction)
    {
        // Get target angle
        float targetAngle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 90f;

        // Rotate smoothly towards the target angle
        float newAngle = Mathf.LerpAngle(transform.eulerAngles.z, targetAngle, rotationSpeed * Time.deltaTime);
        transform.rotation = Quaternion.Euler(0, 0, newAngle);
    }
}
