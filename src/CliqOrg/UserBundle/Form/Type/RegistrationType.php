<?php

namespace CliqOrg\UserBundle\Form\Type;

use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\FormBuilderInterface;

class RegistrationType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options)
    {
        $builder->add('username', 'text');
        $builder->add(
            'password',
            'repeated',
            array(
                 'first_name'  => 'password',
                 'second_name' => 'confirm_password',
                 'type'        => 'password'
            )
        );
        $builder->add('register', 'submit');
    }

    /**
     * Returns the name of this type.
     *
     * @return string The name of this type
     */
    public function getName()
    {
        return 'register';
    }

}