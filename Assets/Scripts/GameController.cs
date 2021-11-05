using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public int target = 120;

    void Awake()
    {
        //QualitySettings.vSyncCount = 1;
        Application.targetFrameRate = target;
    }

}
