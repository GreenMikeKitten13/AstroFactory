using UnityEngine;

public class PlayerScript : MonoBehaviour
{
    float vertical;
    float horizontal;
    readonly float speed = 5.0f;
    readonly float rotationSpeed = 360f; // Degrees per second


    void Update()
    {
        vertical = Input.GetAxis("Vertical");
        horizontal = Input.GetAxis("Horizontal");

        Debug.Log("Vertical: " + vertical + " Horizontal: " + horizontal);

        if (vertical != 0 || horizontal != 0)
            Move();
    }

    void Move()
    {
        Vector3 movement = new Vector2(horizontal, vertical);
        Quaternion targetRotation = Quaternion.LookRotation(Vector3.forward, movement);
        transform.position += speed * Time.deltaTime * movement;
        transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
    }
}
