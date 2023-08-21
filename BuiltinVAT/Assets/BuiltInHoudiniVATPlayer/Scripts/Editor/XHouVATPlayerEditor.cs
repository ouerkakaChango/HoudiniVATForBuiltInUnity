using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(XHouVATPlayer))]
public class XHouVATPlayerEditor : Editor
{
    XHouVATPlayer Target;
    int testFrame;
    void OnEnable()
    {
        Target = (XHouVATPlayer)target;
    }

    //@@@
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        //SerializedProperty weaponTime = serializedObject.FindProperty("weaponTime");
        //EditorGUILayout.PropertyField(weaponTime, new GUIContent("weaponTime"), true);

        if (Application.isPlaying)
        {
            testFrame = EditorGUILayout.IntField("testFrame", testFrame);
            if (GUILayout.Button("[Runtime]StopAtFrame"))
            {
                Target.StopAtFrame(testFrame);
            }
        }

        serializedObject.ApplyModifiedProperties();
    }
}
