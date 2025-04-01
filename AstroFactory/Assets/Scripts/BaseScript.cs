using UnityEngine;
using System.Collections;

public class BaseScript : MonoBehaviour
{
    int health = 100;
    bool cooldown = false;

    private void OnTriggerEnter2D(Collider2D collision)
    {
        if (collision.gameObject.CompareTag("Bullet") && !cooldown)
        {
            StartCoroutine(LooseHealth());
        }
    }

    private IEnumerator LooseHealth()
    {
        cooldown = true;
        health -= 5;

        
        Debug.Log(health.ToString().Length);
        if (health.ToString().Length == 1)
        {
            transform.tag = "00"+health + "hp";
        }
        else if (health.ToString().Length == 2)
        {
            transform.tag = "0" + health + "hp";
        }
        else
        {
            transform.tag = health + "hp";
        }

        if (health <= 0)
        {
            Destroy(gameObject);
        }

        yield return new WaitForSeconds(0.5f);
        cooldown = false;
    }
}
