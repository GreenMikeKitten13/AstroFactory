using UnityEngine;
using System.Collections;

public class CreateEnemy : MonoBehaviour
{

    public GameObject enemyPrefab;
    public GameObject basePrefab;
    private void Start()
    {
        StartCoroutine(CreateBase());
        StartCoroutine(CreateEnemyCoroutine());
    }

    IEnumerator CreateBase()
    {
        yield return new WaitForSeconds(1f);
        GameObject Base = Instantiate(basePrefab, new(5, 5), Quaternion.identity);
        Base.name = "Base";
    }

    private IEnumerator CreateEnemyCoroutine()
    {
        yield return new WaitForSeconds(2f);
        GameObject Enemy =  Instantiate(enemyPrefab, new(10, 10), Quaternion.identity);
        Enemy.name = "Dreieck";
    }
}
