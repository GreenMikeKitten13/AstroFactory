using UnityEngine;

public class PlayerScript : MonoBehaviour
{
    float vertical;
    float horizontal;
    readonly float speed = 5.0f;

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
        transform.position += speed * Time.deltaTime * movement;
    }
}
