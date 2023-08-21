using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//sidefx/vertex_rigid_body_shader
public class XHouVATPlayer : MonoBehaviour
{
    public bool playOnStart = false;
    public float FPS = 24;
    public bool loop = false;

    MeshRenderer mr;
    Material mat;
    int frameNum;
    int F;
    float delta_anim;
    float t_anim;

    bool doing = false;
    bool done = false;
    // Start is called before the first frame update
    void Start()
    {
        mr = GetComponent<MeshRenderer>();
        mat = mr.material;
        frameNum = mat.GetInt("_numOfFrames");
        delta_anim = 1.0f / FPS;
        mat.SetFloat("_speed",1.0f);
        if (playOnStart)
        {
            DoPlay();
        }
    }

    // Update is called once per frame
    void Update()
    {
        if(doing)
        {
            t_anim += Time.deltaTime;
            if(t_anim >= delta_anim)
            {
                UpdateVAT();
                t_anim = 0;
            }
        }
    }
    //################################################
    public void DoPlay()
    {
        t_anim = 0;
        F = 0;
        doing = true;
    }

    public void StopAtFrame(int frame)
    {
        mat.SetFloat("_CurrentTime", frame / (float)frameNum);
        StopAnim();
    }

    //################################################

    void UpdateVAT()
    {
        //Debug.Log("UpdateVAT "+F+" "+frameNum);
        mat.SetFloat("_CurrentTime", F / (float)frameNum);
        F++;
        if(F==frameNum)
        {
            StopAnim();
            if (loop)
            {
                done = false;
                DoPlay();
            }
        }
    }

    void StopAnim()
    {
        doing = false;
        done = true;
    }
}
