using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class Player : MonoBehaviour
{
    Animator animator;
   
 
    Vector2 playerInputVec;
    bool isRunning;
    Vector3 playerMovement;
    public float rotateSpeed = 1000f;
    Transform playerTransform;
    float currentSpeed;
    float targetSpeed;
    public float walkSpeed = 1.620212f;
    public float runSpeed = 4.205853f;
    public Transform rightHandPosition;
    public Transform leftHandPosition;


    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        playerTransform = transform;
    }
   void Update()
    {
        RotatePlayer();
        MovePlayer();   
    }
   /*private void OnAnimatorIK(int layerIndex)
    {
        animator.SetIKPosition(AvatarIKGoal.RightHand, rightHandPosition.position);
        animator.SetIKRotation(AvatarIKGoal.RightHand,rightHandPosition.rotation);
        animator.SetIKPosition(AvatarIKGoal.LeftHand, leftHandPosition.position);
        animator.SetIKRotation(AvatarIKGoal.LeftHand,leftHandPosition.rotation);
        animator.SetIKPositionWeight(AvatarIKGoal.LeftHand,1f);
        animator.SetIKRotationWeight(AvatarIKGoal.LeftHand,1f);
        animator.SetIKPositionWeight(AvatarIKGoal.RightHand, 1f);
        animator.SetIKRotationWeight(AvatarIKGoal.RightHand, 1f);
    }*/
    public void GetPlayerMoveInput(InputAction.CallbackContext ctx)
    {
      playerInputVec = ctx.ReadValue<Vector2>();  
         
    }
    public void GetPlayerAim(InputAction.CallbackContext ctx)
    {
        if(ctx.action.phase==InputActionPhase.Started)
        {
            animator.SetBool("IsAiming", true);
        }
        else if(ctx.action.phase==InputActionPhase.Canceled)
        {
            animator.SetBool("IsAiming", false);
        }


    }
    public void GetPlayerRunInput(InputAction.CallbackContext ctx)
    {
        isRunning = ctx.ReadValue<float>() > 0 ? true : false;
        Debug.Log(isRunning);
    }
     void RotatePlayer()  
    {
        if (playerInputVec.Equals(Vector2.zero)) return;
        playerMovement.x = playerInputVec.x;
        playerMovement.z = playerInputVec.y;
        Quaternion targetRotation = Quaternion.LookRotation(playerMovement, Vector3.up);
        playerTransform.rotation = Quaternion.RotateTowards(playerTransform.rotation, targetRotation, rotateSpeed * Time.deltaTime);
    }
    void MovePlayer()
    {
        targetSpeed = isRunning ? runSpeed : walkSpeed;
        targetSpeed *= playerInputVec.magnitude;
        currentSpeed = Mathf.Lerp(currentSpeed, targetSpeed, 0.9f);
        animator.SetFloat("Speed", currentSpeed);
    }






  
}
