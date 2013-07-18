<?php

namespace CliqOrg\UserBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use CliqOrg\UserBundle\Entity\User;
use Symfony\Component\Form\RequestHandlerInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use CliqOrg\UserBundle\Form\Type\RegistrationType;

class RegistrationController extends Controller
{
    public function indexAction()
    {
        $user = new User();
        $registerForm = $this->createForm(new RegistrationType(), new User());

        return $this->render(
            'CliqOrgUserBundle:Registration:register.html.twig',
            array('registerForm' => $registerForm->createView())
        );
    }

    public function registerAction(Request $request)
    {
        $registerForm = $this->createForm(new RegistrationType(), new User());

        $registerForm->handleRequest($request);

        if ($registerForm->isValid()) {
            $user = $registerForm->getData();
            $em = $this->getDoctrine()->getManager();
            $em->persist($user);
            $em->flush();
            $this->get('session')->getFlashBag()->add('notice', 'REGISTER_SUCCESS');

            return $this->redirect($this->generateUrl('cliq_org_user_register_done'));
        }

        return $this->render(
            'CliqOrgUserBundle:Registration:register.html.twig',
            array('registerForm' => $registerForm->createView())
        );
    }

    public function doneAction()
    {
        return $this->render('CliqOrgUserBundle:Registration:done.html.twig');
    }
}
